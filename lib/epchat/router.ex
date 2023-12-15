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

  forward "/api/v1", to: Epchat.ApiRouter

  get "/ws" do
    conn = fetch_query_params conn
    case conn.params do
      %{"u" => user_id} ->
        case Epchat.Db.Users.get user_id do
          {:error, _reason} ->
            send_resp conn, 500, "Internal Error"
          nil ->
            send_resp conn, 400, "Error: Bad or missing parameters"
          _user ->
            conn
            |> WebSockAdapter.upgrade(Epchat.ChannelHandler, [], timeout: 60_000)
            |> halt()
        end
      _ ->
        send_resp conn, 400, "Error: Bad or missing parameters"

    end
  end

  match _ do
    send_resp conn, 404, "not found"
  end
end
