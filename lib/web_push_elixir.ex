defmodule WebPushElixir do
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

  defp encrypt(
         message,
         auth,
         p256dh,
         vapid_public_key,
         vapid_private_key
       ) do
    client_public_key = url_decode(p256dh)
    client_auth_secret = url_decode(auth)

    salt = :crypto.strong_rand_bytes(16)

    shared_secret = :crypto.compute_key(:ecdh, client_public_key, vapid_private_key, :prime256v1)

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
        <<byte_size(vapid_public_key)::unsigned-big-integer-size(16)>> <> vapid_public_key

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

    {cipher_text, cipher_tag} =
      :crypto.crypto_one_time_aead(
        :aes_128_gcm,
        content_encryption_key,
        nonce,
        message,
        "",
        true
      )

    %{ciphertext: cipher_text <> cipher_tag, salt: salt}
  end

  defp sign_json_web_token(endpoint, vapid_public_key, vapid_private_key) do
    json_web_token =
      JOSE.JWT.from_map(%{
        aud: URI.parse(endpoint).scheme <> "://" <> URI.parse(endpoint).host,
        exp: DateTime.to_unix(DateTime.utc_now()) + 12 * 3600,
        sub: System.get_env("VAPID_SUBJECT")
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

  def send_notification(subscription, message) do
    vapid_public_key = url_decode(System.get_env("VAPID_PUBLIC_KEY"))
    vapid_private_key = url_decode(System.get_env("VAPID_PRIVATE_KEY"))

    %{endpoint: endpoint, keys: %{auth: auth, p256dh: p256dh}} =
      Jason.decode!(subscription, keys: :atoms)

    encrypted = encrypt(message, auth, p256dh, vapid_public_key, vapid_private_key)

    signed_json_web_token =
      sign_json_web_token(endpoint, vapid_public_key, vapid_private_key)

    HTTPoison.post(endpoint, encrypted.ciphertext, %{
      "Authorization" => "WebPush #{signed_json_web_token}",
      "Content-Encoding" => "aesgcm",
      "Crypto-Key" => "p256ecdsa=#{url_encode(vapid_public_key)}",
      "Encryption" => "salt=#{url_encode(encrypted.salt)}",
      "TTL" => "60"
    })
  end
end
