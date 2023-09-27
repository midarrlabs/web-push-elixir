defmodule GenerateVapidKeysTest do
  use ExUnit.Case

  test "it should generate" do
    assert %{
             vapid_public_key: <<_vapid_public_key::binary>>,
             vapid_private_key: <<_vapid_private_key::binary>>,
             vapid_subject: "mailto:admin@email.com"
           } = Mix.Tasks.Generate.Vapid.Keys.run([])
  end
end
