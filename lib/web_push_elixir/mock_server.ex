defmodule WebPushElixir.MockServer do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  post "/some-endpoint" do
    conn
    |> Plug.Conn.send_resp(200, "ok")
  end

  get "/" do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> Plug.Conn.send_file(200, "./lib/web_push_elixir/index.html")
  end

  get "/app.webmanifest" do
    conn
    |> put_resp_header("content-type", "application/manifest+json")
    |> Plug.Conn.send_file(200, "./lib/web_push_elixir/app.webmanifest")
  end

  get "/main.js" do
    conn
    |> put_resp_header("content-type", "application/x-javascript")
    |> Plug.Conn.send_file(200, "./lib/web_push_elixir/main.js")
  end

  get "/service-worker.js" do
    conn
    |> put_resp_header("content-type", "application/x-javascript")
    |> Plug.Conn.send_file(200, "./lib/web_push_elixir/service-worker.js")
  end

  get "/favicon.ico" do
    conn
    |> put_resp_header("content-type", "image/x-icon")
    |> Plug.Conn.send_file(200, "./lib/web_push_elixir/favicon.ico")
  end
end
