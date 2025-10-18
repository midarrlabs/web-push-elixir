defmodule WebPushElixirTest do
  use ExUnit.Case

  @subscription """
  {"endpoint":"http://localhost:4040/some-push-service","keys":{"p256dh":"BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM=","auth":"tBHItJI5svbpez7KI4CCXg=="}}
  """

  test "it should send notification" do
    %{
      vapid_public_key: vapid_public_key,
      vapid_private_key: vapid_private_key,
      vapid_subject: vapid_subject
    } = Mix.Tasks.Generate.Vapid.Keys.run([])

    Application.put_env(:web_push_elixir, :vapid_public_key, vapid_public_key)

    Application.put_env(:web_push_elixir, :vapid_private_key, vapid_private_key)

    Application.put_env(:web_push_elixir, :vapid_subject, vapid_subject)

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
             {"content-length", "1578"},
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
             {"content-length", "1911"},
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
