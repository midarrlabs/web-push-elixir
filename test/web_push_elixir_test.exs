defmodule WebPushElixirTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  @subscription_from_client '{"endpoint":"https://some.pushservice.com/something-unique","keys":{"p256dh":"BIPUL12DLfytvTajnryr2PRdAgXS3HGKiLqndGcJGabyhHheJYlNGCeXl1dn18gSJ1WAkAPIxr4gK0_dQds4yiI=","auth":"FPssNDTKnInHVndSTdbKFw=="}}'
  @subscription_decoded %{
    endpoint: "https://some.pushservice.com/something-unique",
    keys: %{
      auth: "FPssNDTKnInHVndSTdbKFw==",
      p256dh:
        "BIPUL12DLfytvTajnryr2PRdAgXS3HGKiLqndGcJGabyhHheJYlNGCeXl1dn18gSJ1WAkAPIxr4gK0_dQds4yiI="
    }
  }

  @salt_length 16
  @server_public_key_length 65

  test "it should gen keypair" do
    assert capture_log(WebPushElixir.gen_keypair()) =~ "public_key:"
    assert capture_log(WebPushElixir.gen_keypair()) =~ "private_key:"
    assert capture_log(WebPushElixir.gen_keypair()) =~ "subject:"
    assert capture_log(WebPushElixir.gen_keypair()) =~ "mailto:admin@email.com"
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
end
