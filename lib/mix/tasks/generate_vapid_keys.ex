defmodule Mix.Tasks.Generate.Vapid.Keys do
  @moduledoc "The mix task: `mix help generate.vapid.keys`"
  use Mix.Task

  @shortdoc "Generate vapid keys"
  def run(_args) do
    {public_key, private_key} = :crypto.generate_key(:ecdh, :prime256v1)

    %{
      vapid_public_key: Base.url_encode64(public_key, padding: false),
      vapid_private_key: Base.url_encode64(private_key, padding: false),
      vapid_subject: "mailto:admin@email.com"
    }
  end
end
