defmodule WebPushElixirTest do
  use ExUnit.Case

  @test_subscription %{
    "endpoint" => "http://localhost:4040/some-push-service",
    "keys" => %{
      "p256dh" =>
        "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM=",
      "auth" => "tBHItJI5svbpez7KI4CCXg=="
    }
  }

  test "it should send notification" do
    subscription = Jason.encode!(@test_subscription)

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

  test "it should respect the custom ttl argument" do
    subscription = Jason.encode!(@test_subscription)

    {:ok, response} = WebPushElixir.send_notification(subscription, "some message", ttl: 300)

    assert ["300"] = Map.get(response.request.headers, "ttl")
  end

  test "it should send the urgency parameter" do
    subscription = Jason.encode!(@test_subscription)

    {:ok, response} =
      WebPushElixir.send_notification(subscription, "some message", urgency: :high)

    assert ["high"] = Map.get(response.request.headers, "urgency")
  end

  test "it should set the topic if it is provided" do
    subscription = Jason.encode!(@test_subscription)

    {:ok, response} =
      WebPushElixir.send_notification(subscription, "some message", topic: "some-test-topic")

    assert ["some-test-topic"] = Map.get(response.request.headers, "topic")
  end

  test "it should return expired" do
    expired_subscription =
      Jason.encode!(%{@test_subscription | "endpoint" => "http://localhost:4040/gone"})

    assert {:error, :expired} = WebPushElixir.send_notification(expired_subscription, "message")
  end

  test "it should return http error" do
    error_subscription =
      Jason.encode!(%{@test_subscription | "endpoint" => "http://localhost:4040/error"})

    assert {:error, {:http_error, status, _body}} =
             WebPushElixir.send_notification(error_subscription, "message")

    assert status != 200..202
  end

  test "it should return transport error" do
    transport_error_subscription = Jason.encode!(%{@test_subscription | "endpoint" => "http://localhost:4041/some-push-service"})

    assert {:error, {:transport_error, _reason}} =
             WebPushElixir.send_notification(transport_error_subscription, "message")
  end
end
