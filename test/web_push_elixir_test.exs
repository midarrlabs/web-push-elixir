defmodule WebPushElixirTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  test "it should gen keypair" do
    assert capture_log(WebPushElixir.gen_keypair()) =~ "public_key:"
    assert capture_log(WebPushElixir.gen_keypair()) =~ "private_key:"
    assert capture_log(WebPushElixir.gen_keypair()) =~ "subject:"
    assert capture_log(WebPushElixir.gen_keypair()) =~ "mailto:admin@email.com"
  end
end
