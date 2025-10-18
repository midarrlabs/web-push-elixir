defmodule WebPushElixir.MockServer do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  post "/some-push-service" do
    conn
    |> Plug.Conn.send_resp(200, "ok")
  end

  get "/" do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> Plug.Conn.send_file(200, "./example/index.html")
  end

  get "/app.webmanifest" do
    conn
    |> put_resp_header("content-type", "application/manifest+json")
    |> Plug.Conn.send_file(200, "./example/app.webmanifest")
  end

  get "/main.js" do
    conn
    |> put_resp_header("content-type", "application/x-javascript")
    |> Plug.Conn.send_file(200, "./example/main.js")
  end

  get "/service-worker.js" do
    conn
    |> put_resp_header("content-type", "application/x-javascript")
    |> Plug.Conn.send_file(200, "./example/service-worker.js")
  end

  get "/web-push-elixir/service-worker.js" do
    conn
    |> put_resp_header("content-type", "application/x-javascript")
    |> Plug.Conn.send_file(200, "./example/service-worker.js")
  end

  get "/favicon.ico" do
    conn
    |> put_resp_header("content-type", "image/x-icon")
    |> Plug.Conn.send_file(200, "./example/favicon.ico")
  end
end
