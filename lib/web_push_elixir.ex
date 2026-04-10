defmodule WebPushElixir do
  @moduledoc """
  Module to send web push notifications with an encrypted payload.
  """

  defp url_encode(string) do
    Base.url_encode64(string, padding: false)
  end

  defp url_decode(string) do
    Base.url_decode64!(string, padding: false)
  end

  defp hmac_based_key_derivation_function(salt, initial_keying_material, info, length) do
    pseudo_random_key =
      :crypto.mac_init(:hmac, :sha256, salt)
      |> :crypto.mac_update(initial_keying_material)
      |> :crypto.mac_final()

    :crypto.mac_init(:hmac, :sha256, pseudo_random_key)
    |> :crypto.mac_update(info)
    |> :crypto.mac_update(<<1>>)
    |> :crypto.mac_final()
    |> :binary.part(0, length)
  end

  defp encrypt_payload(message, p256dh, auth) do
    client_public_key = url_decode(p256dh)
    client_auth_secret = url_decode(auth)

    salt = :crypto.strong_rand_bytes(16)

    {local_public_key, local_private_key} = :crypto.generate_key(:ecdh, :prime256v1)

    shared_secret = :crypto.compute_key(:ecdh, client_public_key, local_private_key, :prime256v1)

    pseudo_random_key =
      hmac_based_key_derivation_function(
        client_auth_secret,
        shared_secret,
        "Content-Encoding: auth" <> <<0>>,
        32
      )

    context =
      <<0, byte_size(client_public_key)::unsigned-big-integer-size(16)>> <>
        client_public_key <>
        <<byte_size(local_public_key)::unsigned-big-integer-size(16)>> <> local_public_key

    content_encryption_key_info = "Content-Encoding: aesgcm" <> <<0>> <> "P-256" <> context

    content_encryption_key =
      hmac_based_key_derivation_function(salt, pseudo_random_key, content_encryption_key_info, 16)

    nonce =
      hmac_based_key_derivation_function(
        salt,
        pseudo_random_key,
        "Content-Encoding: nonce" <> <<0>> <> "P-256" <> context,
        12
      )

    padded_message = <<0::unsigned-big-integer-size(16)>> <> :binary.copy(<<0>>, 0) <> message

    {cipher_text, cipher_tag} =
      :crypto.crypto_one_time_aead(
        :aes_128_gcm,
        content_encryption_key,
        nonce,
        padded_message,
        <<>>,
        true
      )

    %{ciphertext: cipher_text <> cipher_tag, salt: salt, local_public_key: local_public_key}
  end

  defp sign_json_web_token(endpoint, vapid_public_key, vapid_private_key) do
    json_web_token =
      JOSE.JWT.from_map(%{
        aud: URI.parse(endpoint).scheme <> "://" <> URI.parse(endpoint).host,
        exp: DateTime.to_unix(DateTime.utc_now()) + 12 * 3600,
        sub: Application.get_env(:web_push_elixir, :vapid_subject)
      })

    json_web_key =
      JOSE.JWK.from_key(
        {:ECPrivateKey, 1, vapid_private_key, {:namedCurve, {1, 2, 840, 10045, 3, 1, 7}},
         vapid_public_key, nil}
      )

    {%{alg: :jose_jws_alg_ecdsa}, signed_json_web_token} =
      JOSE.JWS.compact(JOSE.JWT.sign(json_web_key, %{"alg" => "ES256"}, json_web_token))

    signed_json_web_token
  end

  @doc """
  Sends a web push notification with an encrypted payload.

  ## Arguments

  * `subscription` - the subscription JSON string received from the client
  * `message` - the message string to send
  * `opts` - Optional message options, currently:
      * `ttl`: time to live in seconds if the client is disconnected, defaults to 60 seconds
      * `urgency`: Urgency of the message, one of: `:very-low`, `:low`, `:normal`, `:high`
      * `topic`: a string with a topic, that is used to replace previous same topic notifications

  ## Examples

      case WebPushElixir.send_notification(subscription, "Hello!") do
        {:ok, _response} ->
          :ok

        {:error, :expired} ->
          Repo.delete(subscription)

        {:error, {:http_error, status, body}} ->
          Logger.error("HTTP error \#{status}: \#{body}")
      end

  ## Return Values

  * `{:ok, response}` - notification sent successfully (HTTP 200-202)
  * `{:error, :expired}` - subscription expired/not found (HTTP 404 or 410)
  * `{:error, {:http_error, status, body}}` - HTTP error from push service
  """
  def send_notification(subscription, message, opts \\ []) when is_list(opts) do
    vapid_public_key = url_decode(Application.get_env(:web_push_elixir, :vapid_public_key))
    vapid_private_key = url_decode(Application.get_env(:web_push_elixir, :vapid_private_key))

    ttl = Keyword.get(opts, :ttl, 60)
    urgency = Keyword.get(opts, :urgency, nil)
    topic = Keyword.get(opts, :topic, nil)

    %{"endpoint" => endpoint, "keys" => %{"p256dh" => p256dh, "auth" => auth}} =
      Jason.decode!(subscription)

    encrypted_payload = encrypt_payload(message, p256dh, auth)

    signed_json_web_token =
      sign_json_web_token(endpoint, vapid_public_key, vapid_private_key)

    headers = [
      {"authorization", "WebPush #{signed_json_web_token}"},
      {"content-encoding", "aesgcm"},
      {"content-length", "#{byte_size(encrypted_payload.ciphertext)}"},
      {"content-type", "application/octet-stream"},
      {"crypto-key", "dh=#{url_encode(encrypted_payload.local_public_key)};p256ecdsa=#{url_encode(vapid_public_key)}"},
      {"encryption", "salt=#{url_encode(encrypted_payload.salt)}"},
      {"ttl", "#{ttl}"}
    ]

    headers = if urgency, do: [{"urgency", Atom.to_string(urgency)} | headers], else: headers
    headers = if topic, do: [{"topic", topic} | headers], else: headers

    case Req.run(
      method: :post,
      url: endpoint,
      body: encrypted_payload.ciphertext,
      headers: headers
    ) do
      {request, %{status: status} = response} when status in 200..202 ->
        {:ok, Map.put(response, :request, request)}

      {_request, %{status: status}} when status in [404, 410] ->
        {:error, :expired}

      {_request, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}
    end
  end
end
