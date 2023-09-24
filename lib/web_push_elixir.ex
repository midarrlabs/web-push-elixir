defmodule WebPushElixir do
  require Logger

  def gen_key_pair() do
    {public, private} = :crypto.generate_key(:ecdh, :prime256v1)

    {Base.url_encode64(public, padding: false), Base.url_encode64(private, padding: false)}
  end

  def output_key_pair({public, private}) do
    fn ->
      Logger.info(%{:public_key => public})
      Logger.info(%{:private_key => private})

      Logger.info(%{:subject => "mailto:admin@email.com"})
    end
  end

  defp encrypt(message, subscription) do
    client_public_key = Base.url_decode64!(subscription.keys.p256dh, padding: false)
    client_auth_secret = Base.url_decode64!(subscription.keys.auth, padding: false)

    salt = :crypto.strong_rand_bytes(16)

    {server_public_key, server_private_key} = :crypto.generate_key(:ecdh, :prime256v1)

    shared_secret = :crypto.compute_key(:ecdh, client_public_key, server_private_key, :prime256v1)

    prk = hkdf(client_auth_secret, shared_secret, "Content-Encoding: auth" <> <<0>>, 32)

    context =
      <<0, byte_size(client_public_key)::unsigned-big-integer-size(16)>> <>
        client_public_key <>
        <<byte_size(server_public_key)::unsigned-big-integer-size(16)>> <> server_public_key

    content_encryption_key_info = "Content-Encoding: " <> "aesgcm" <> <<0>> <> "P-256" <> context
    content_encryption_key = hkdf(salt, prk, content_encryption_key_info, 16)

    nonce = hkdf(salt, prk, "Content-Encoding: " <> "nonce" <> <<0>> <> "P-256" <> context, 12)

    {cipher_text, cipher_tag} =
      :crypto.crypto_one_time_aead(
        :aes_128_gcm,
        content_encryption_key,
        nonce,
        message,
        "",
        true
      )

    %{ciphertext: cipher_text <> cipher_tag, salt: salt, server_public_key: server_public_key}
  end

  defp hkdf(salt, ikm, info, length) do
    prk =
      :crypto.mac_init(:hmac, :sha256, salt)
      |> :crypto.mac_update(ikm)
      |> :crypto.mac_final()

    :crypto.mac_init(:hmac, :sha256, prk)
    |> :crypto.mac_update(info)
    |> :crypto.mac_update(<<1>>)
    |> :crypto.mac_final()
    |> :binary.part(0, length)
  end

  def get_headers(audience) do
    expiration_timestamp = DateTime.to_unix(DateTime.utc_now()) + 12 * 3600

    public_key = Base.url_decode64!(System.get_env("PUBLIC_KEY"), padding: false)
    private_key = Base.url_decode64!(System.get_env("PRIVATE_KEY"), padding: false)

    payload =
      %{
        aud: audience,
        exp: expiration_timestamp,
        sub: System.get_env("SUBJECT")
      }
      |> JOSE.JWT.from_map()

    jwk =
      {:ECPrivateKey, 1, private_key, {:namedCurve, {1, 2, 840, 10045, 3, 1, 7}}, public_key, nil}
      |> JOSE.JWK.from_key()

    {_, jwt} = JOSE.JWS.compact(JOSE.JWT.sign(jwk, %{"alg" => "ES256"}, payload))

    %{
      "Authorization" => "WebPush " <> jwt,
      "Crypto-Key" => "p256ecdsa=" <> System.get_env("PUBLIC_KEY")
    }
  end

  def send_web_push(message, %{endpoint: endpoint} = subscription) do
    payload = encrypt(message, subscription)

    parsed = URI.parse(endpoint)

    headers =
      get_headers(parsed.scheme <> "://" <> parsed.host)
      |> Map.merge(%{
        "TTL" => "0",
        "Content-Encoding" => "aesgcm",
        "Encryption" => "salt=#{Base.url_encode64(payload.salt, padding: false)}",
        "Crypto-Key" => "dh=#{Base.url_encode64(payload.server_public_key, padding: false)};"
      })

    HTTPoison.post(endpoint, payload.ciphertext, headers)
  end
end
