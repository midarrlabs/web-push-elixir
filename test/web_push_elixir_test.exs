defmodule WebPushElixirTest do
  use ExUnit.Case

  test "it should send notification" do
      subscription = """
      {"endpoint":"http://localhost:4040/some-push-service","keys":{"p256dh":"BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM=","auth":"tBHItJI5svbpez7KI4CCXg=="}}
      """

    {:ok, response} = WebPushElixir.send_notification(subscription, "some message")

    assert %{
              "authorization" => ["WebPush " <> <<_jwt::binary>>],
              "content-encoding" => ["aesgcm"],
              "content-length" => ["30"],
              "content-type" => ["application/octet-stream"],
              "crypto-key" => ["dh=" <> <<_crypto_keys::binary>>],
              "encryption" => ["salt=" <> <<_salt::binary>>],
              "ttl" => ["60"]
            } = response.request.headers

    assert response.status in 200..202
  end


  test "it should return expired" do
    expired_subscription = """
    {"endpoint":"http://localhost:4040/gone","keys":{"p256dh":"BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM=","auth":"tBHItJI5svbpez7KI4CCXg=="}}
    """

    assert {:error, :expired} = WebPushElixir.send_notification(expired_subscription, "message")
  end

  test "it should return http error" do
    error_subscription = """
    {"endpoint":"http://localhost:4040/error","keys":{"p256dh":"BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM=","auth":"tBHItJI5svbpez7KI4CCXg=="}}
    """

    assert {:error, {:http_error, status, _body}} = WebPushElixir.send_notification(error_subscription, "message")
    assert status != 200..202
  end
end
