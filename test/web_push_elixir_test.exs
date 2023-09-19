defmodule WebPushElixirTest do
  use ExUnit.Case

  test "it should decode" do
    assert Jason.decode!(
             '{"endpoint":"https://some.pushservice.com/something-unique","keys":{"p256dh":"BIPUL12DLfytvTajnryr2PRdAgXS3HGKiLqndGcJGabyhHheJYlNGCeXl1dn18gSJ1WAkAPIxr4gK0_dQds4yiI=","auth":"FPssNDTKnInHVndSTdbKFw=="}}'
           ) == %{
             "endpoint" => "https://some.pushservice.com/something-unique",
             "keys" => %{
               "auth" => "FPssNDTKnInHVndSTdbKFw==",
               "p256dh" =>
                 "BIPUL12DLfytvTajnryr2PRdAgXS3HGKiLqndGcJGabyhHheJYlNGCeXl1dn18gSJ1WAkAPIxr4gK0_dQds4yiI="
             }
           }
  end
end
