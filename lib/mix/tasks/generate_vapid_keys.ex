defmodule Mix.Tasks.Generate.Vapid.Keys do
  @moduledoc "The mix task: `mix help generate.vapid.keys`"
  use Mix.Task

  @shortdoc "Generate vapid keys"
  def run(_) do
    WebPushElixir.output_key_pair(WebPushElixir.gen_key_pair()).()
  end
end