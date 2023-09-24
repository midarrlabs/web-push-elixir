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

    assert {
             true,
             %JOSE.JWT{
               fields: %{
                 "aud" => "http://localhost/",
                 "exp" => _expiry,
                 "sub" => "mailto:admin@email.com"
               }
             },
             %JOSE.JWS{
               alg: {:jose_jws_alg_ecdsa, :ES256},
               b64: :undefined,
               fields: %{"typ" => "JWT"}
             }
           } = JOSE.JWT.verify_strict(jwk, ["ES256"], jwt)
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

  test "it should have index headers" do
    {:ok, response} = HTTPoison.get(~c"http://localhost:4040")

    assert [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"content-length", "348"},
             {"content-type", "text/html; charset=utf-8"},
             {"date", <<_date::binary>>},
             {"server", "Cowboy"}
           ] = response.headers
  end

  test "it should have mainfest headers" do
    {:ok, response} = HTTPoison.get(~c"http://localhost:4040/app.webmanifest")

    assert [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"content-length", "58"},
             {"content-type", "application/manifest+json"},
             {"date", <<_date::binary>>},
             {"server", "Cowboy"}
           ] = response.headers
  end

  test "it should have main js headers" do
    {:ok, response} = HTTPoison.get(~c"http://localhost:4040/main.js")

    assert [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"content-length", "784"},
             {"content-type", "application/x-javascript"},
             {"date", <<_date::binary>>},
             {"server", "Cowboy"}
           ] = response.headers
  end

  test "it should have service worker headers" do
    {:ok, response} = HTTPoison.get(~c"http://localhost:4040/web-push-elixir/service-worker.js")

    assert [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"content-length", "208"},
             {"content-type", "application/x-javascript"},
             {"date", <<_date::binary>>},
             {"server", "Cowboy"}
           ] = response.headers
  end

  test "it should have favicon headers" do
    {:ok, response} = HTTPoison.get(~c"http://localhost:4040/favicon.ico")

    assert [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"content-length", "1150"},
             {"content-type", "image/x-icon"},
             {"date", <<_date::binary>>},
             {"server", "Cowboy"}
           ] = response.headers
  end
end
