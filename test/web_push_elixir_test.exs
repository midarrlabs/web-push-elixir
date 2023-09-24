defmodule WebPushElixirTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  @subscription_from_client ~c"{\"endpoint\":\"http://localhost:4040/some-endpoint\",\"keys\":{\"p256dh\":\"BIPUL12DLfytvTajnryr2PRdAgXS3HGKiLqndGcJGabyhHheJYlNGCeXl1dn18gSJ1WAkAPIxr4gK0_dQds4yiI=\",\"auth\":\"FPssNDTKnInHVndSTdbKFw==\"}}"
  @subscription_decoded %{
    endpoint: "http://localhost:4040/some-endpoint",
    keys: %{
      auth: "FPssNDTKnInHVndSTdbKFw==",
      p256dh:
        "BIPUL12DLfytvTajnryr2PRdAgXS3HGKiLqndGcJGabyhHheJYlNGCeXl1dn18gSJ1WAkAPIxr4gK0_dQds4yiI="
    }
  }

  @salt_length 16
  @server_public_key_length 65

  test "it should output key pair" do
    assert capture_log(WebPushElixir.gen_key_pair() |> WebPushElixir.output_key_pair()) =~
             "public_key:"

    assert capture_log(WebPushElixir.gen_key_pair() |> WebPushElixir.output_key_pair()) =~
             "private_key:"

    assert capture_log(WebPushElixir.gen_key_pair() |> WebPushElixir.output_key_pair()) =~
             "subject:"

    assert capture_log(WebPushElixir.gen_key_pair() |> WebPushElixir.output_key_pair()) =~
             "mailto:admin@email.com"
  end

  test "it should decode" do
    assert Jason.decode!(@subscription_from_client, keys: :atoms) == @subscription_decoded
  end

  test "it should encrypt" do
    response = WebPushElixir.encrypt("some message", @subscription_decoded)

    assert is_binary(response.ciphertext)
    assert is_binary(response.salt)
    assert byte_size(response.salt) == @salt_length
    assert is_binary(response.server_public_key)
    assert byte_size(response.server_public_key) == @server_public_key_length
  end

  test "it should get headers" do
    {public, private} = WebPushElixir.gen_key_pair()

    System.put_env("PUBLIC_KEY", public)

    System.put_env("PRIVATE_KEY", private)

    System.put_env("SUBJECT", "mailto:admin@email.com")

    assert %{"Authorization" => "WebPush " <> jwt, "Crypto-Key" => "p256ecdsa=" <> public_key} =
             WebPushElixir.get_headers("http://localhost/", "aesgcm")

    jwk =
      {:ECPrivateKey, 1, <<>>, {:namedCurve, {1, 2, 840, 10045, 3, 1, 7}},
       Base.url_decode64!(public_key, padding: false), nil}
      |> JOSE.JWK.from_key()

    assert {true, _, _} = JOSE.JWT.verify_strict(jwk, ["ES256"], jwt)
  end

  test "it should send web push" do
    {public, private} = WebPushElixir.gen_key_pair()

    System.put_env("PUBLIC_KEY", public)

    System.put_env("PRIVATE_KEY", private)

    System.put_env("SUBJECT", "mailto:admin@email.com")

    {:ok, response} = WebPushElixir.send_web_push("some message", @subscription_decoded)

    assert [
             {"Authorization", "WebPush " <> <<_JWT::binary>>},
             {"Content-Encoding", "aesgcm"},
             {"Crypto-Key", <<_server_public_key::binary>>},
             {"Encryption", "salt=" <> <<_salt::binary>>},
             {"TTL", "0"}
           ] = response.request.headers

    assert <<_body::binary>> = response.request.body
  end
end
