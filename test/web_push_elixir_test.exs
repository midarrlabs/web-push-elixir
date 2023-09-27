defmodule WebPushElixirTest do
  use ExUnit.Case

  @subscription ~c"{\"endpoint\":\"http://localhost:4040/some-push-service\",\"keys\":{\"p256dh\":\"BIPUL12DLfytvTajnryr2PRdAgXS3HGKiLqndGcJGabyhHheJYlNGCeXl1dn18gSJ1WAkAPIxr4gK0_dQds4yiI=\",\"auth\":\"FPssNDTKnInHVndSTdbKFw==\"}}"

  test "it should send notification" do
    %{
      vapid_public_key: vapid_public_key,
      vapid_private_key: vapid_private_key,
      vapid_subject: vapid_subject
    } = Mix.Tasks.Generate.Vapid.Keys.run([])

    System.put_env("VAPID_PUBLIC_KEY", vapid_public_key)

    System.put_env("VAPID_PRIVATE_KEY", vapid_private_key)

    System.put_env("VAPID_SUBJECT", vapid_subject)

    {:ok, response} = WebPushElixir.send_notification(@subscription, "some message")

    assert [
             {"Authorization", "WebPush " <> <<_jwt::binary>>},
             {"Content-Encoding", "aesgcm"},
             {"Content-Length", "30"},
             {"Content-Type", "application/octet-stream"},
             {"Crypto-Key", <<_crypto_keys::binary>>},
             {"Encryption", "salt=" <> <<_salt::binary>>},
             {"TTL", "60"}
           ] = response.request.headers

    assert <<_body::binary>> = response.request.body
  end

  test "it should have index headers" do
    {:ok, response} = HTTPoison.get(~c"http://localhost:4040")

    assert [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"content-length", "611"},
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
             {"content-length", "887"},
             {"content-type", "application/x-javascript"},
             {"date", <<_date::binary>>},
             {"server", "Cowboy"}
           ] = response.headers
  end

  test "it should have service worker headers" do
    {:ok, response} = HTTPoison.get(~c"http://localhost:4040/service-worker.js")

    assert [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"content-length", "262"},
             {"content-type", "application/x-javascript"},
             {"date", <<_date::binary>>},
             {"server", "Cowboy"}
           ] = response.headers
  end

  test "it should have static service worker headers" do
    {:ok, response} = HTTPoison.get(~c"http://localhost:4040/web-push-elixir/service-worker.js")

    assert [
             {"cache-control", "max-age=0, private, must-revalidate"},
             {"content-length", "262"},
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
