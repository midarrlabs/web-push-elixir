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

  test "it should output key pair" do
    assert capture_log(WebPushElixir.output_key_pair(WebPushElixir.gen_key_pair())) =~
             "public_key:"

    assert capture_log(WebPushElixir.output_key_pair(WebPushElixir.gen_key_pair())) =~
             "private_key:"

    assert capture_log(WebPushElixir.output_key_pair(WebPushElixir.gen_key_pair())) =~
             "subject:"

    assert capture_log(WebPushElixir.output_key_pair(WebPushElixir.gen_key_pair())) =~
             "mailto:admin@email.com"
  end

  test "it should decode" do
    assert Jason.decode!(@subscription_from_client, keys: :atoms) == @subscription_decoded
  end

  test "it should send notification" do
    {public, private} = WebPushElixir.gen_key_pair()

    System.put_env("VAPID_PUBLIC_KEY", public)

    System.put_env("VAPID_PRIVATE_KEY", private)

    System.put_env("VAPID_SUBJECT", "mailto:admin@email.com")

    {:ok, response} = WebPushElixir.send_notification(@subscription_decoded, "some message")

    assert [
             {"Authorization", "WebPush " <> <<_jwt::binary>>},
             {"Content-Encoding", "aesgcm"},
             {"Crypto-Key", "dh=" <> <<_server_public_key::binary>>},
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
