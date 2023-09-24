ExUnit.start()

DynamicSupervisor.start_child(
  WebPushElixir.DynamicSupervisor,
  {Plug.Cowboy, scheme: :http, plug: WebPushElixir.MockServer, options: [port: 4040]}
)
