defmodule Epchat.ApiRouter do
  require Logger
  use Plug.Router
  alias Epchat.Controllers

  plug Plug.Logger
  plug :match
  plug Plug.Parsers, parsers: [{:json, json_decoder: Jason}]
  plug :dispatch

  # CORS management
  options _ do
    opts = [
      {"Access-Control-Allow-Origin", "*"},
      {"Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS"},
      {"Access-Control-Allow-Headers", "Content-Type, Accept, Authorization"},
    ]
    conn
    |> merge_resp_headers(opts)
    |> send_resp(204, "")
    |> halt()
  end

  post "/channels/create" do
    Controllers.Channels.create conn, conn.body_params
  end

  post "/channels/join" do
    Controllers.Channels.join conn, conn.body_params
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
