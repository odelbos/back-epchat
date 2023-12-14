defmodule Epchat.Router do

  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, """
    Use the JavaScript console to interact using websockets

    sock  = new WebSocket("ws://localhost:4000/ws")
    sock.addEventListener("message", console.log)
    sock.addEventListener("open", () => sock.send("ping"))
    """)
  end

  forward "/api", to: Epchat.ApiRouter

  get "/ws" do
    conn
    |> WebSockAdapter.upgrade(Epchat.ChannelHandler, [], timeout: 60_000)
    |> halt()
  end

  match _ do
    send_resp conn, 404, "not found"
  end
end
