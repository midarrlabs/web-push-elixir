defmodule WebPushElixir do
  require Logger

  def gen_keypair do
    {public, private} = :crypto.generate_key(:ecdh, :prime256v1)

    fn ->
      Logger.info(%{:public_key => Base.url_encode64(public, padding: false)})
      Logger.info(%{:private_key => Base.url_encode64(private, padding: false)})
      Logger.info(%{:subject => "mailto:admin@email.com"})
    end
  end
end
