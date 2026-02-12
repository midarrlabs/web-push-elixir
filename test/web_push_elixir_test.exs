defmodule WebPushElixirTest do
  use ExUnit.Case

  @subscription """
  {"endpoint":"http://localhost:4040/some-push-service","keys":{"p256dh":"BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM=","auth":"tBHItJI5svbpez7KI4CCXg=="}}
  """

  test "it should send notification" do
    {:ok, response} = WebPushElixir.send_notification(@subscription, "some message")

    assert %{
              "authorization" => ["WebPush " <> <<_jwt::binary>>],
              "content-encoding" => ["aesgcm"],
              "content-length" => ["30"],
              "content-type" => ["application/octet-stream"],
              "crypto-key" => ["dh=" <> <<_crypto_keys::binary>>],
              "encryption" => ["salt=" <> <<_salt::binary>>],
              "ttl" => ["60"]
            } = response.request.headers
  end
end
