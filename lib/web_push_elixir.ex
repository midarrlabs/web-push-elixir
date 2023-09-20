defmodule WebPushElixir do
  require Logger

  @auth_info "Content-Encoding: auth" <> <<0>>
  @one_buffer <<1>>

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

  def encrypt(message, subscription) do
    client_public_key = Base.url_decode64!(subscription.keys.p256dh, padding: false)
    client_auth_secret = Base.url_decode64!(subscription.keys.auth, padding: false)

    salt = :crypto.strong_rand_bytes(16)

    {server_public_key, server_private_key} = :crypto.generate_key(:ecdh, :prime256v1)

    shared_secret = :crypto.compute_key(:ecdh, client_public_key, server_private_key, :prime256v1)

    prk = hkdf(client_auth_secret, shared_secret, @auth_info, 32)

    context = create_context(client_public_key, server_public_key)

    content_encryption_key_info = create_info("aesgcm", context)
    content_encryption_key = hkdf(salt, prk, content_encryption_key_info, 16)

    nonce_info = create_info("nonce", context)
    nonce = hkdf(salt, prk, nonce_info, 12)

    ciphertext = encrypt_payload(message, content_encryption_key, nonce)

    %{ciphertext: ciphertext, salt: salt, server_public_key: server_public_key}
  end

  defp hkdf(salt, ikm, info, length) do
    prk =
      :crypto.mac_init(:hmac, :sha256, salt)
      |> :crypto.mac_update(ikm)
      |> :crypto.mac_final()

    :crypto.mac_init(:hmac, :sha256, prk)
    |> :crypto.mac_update(info)
    |> :crypto.mac_update(@one_buffer)
    |> :crypto.mac_final()
    |> :binary.part(0, length)
  end

  defp create_context(client_public_key, server_public_key) do
    <<0, byte_size(client_public_key)::unsigned-big-integer-size(16)>> <>
      client_public_key <>
      <<byte_size(server_public_key)::unsigned-big-integer-size(16)>> <> server_public_key
  end

  defp create_info(type, context) do
    "Content-Encoding: " <> type <> <<0>> <> "P-256" <> context
  end

  defp encrypt_payload(plaintext, content_encryption_key, nonce) do
    {cipher_text, cipher_tag} =
      :crypto.crypto_one_time_aead(
        :aes_128_gcm,
        content_encryption_key,
        nonce,
        plaintext,
        "",
        true
      )

    cipher_text <> cipher_tag
  end

  def get_headers(audience, content_encoding, expiration \\ 12 * 3600) do
    expiration_timestamp = DateTime.to_unix(DateTime.utc_now()) + expiration

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

    headers(content_encoding, jwt, System.get_env("PUBLIC_KEY"))
  end

  defp headers("aesgcm", jwt, pub) do
    %{"Authorization" => "WebPush " <> jwt, "Crypto-Key" => "p256ecdsa=" <> pub}
  end
end
