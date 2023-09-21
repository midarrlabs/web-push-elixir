defmodule WebPushElixir.MockServer do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  post "/some-endpoint" do
    conn
    |> Plug.Conn.send_resp(200, "ok")
  end
end
