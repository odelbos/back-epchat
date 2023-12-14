defmodule Epchat.ApiRouter do
  require Logger
  use Plug.Router

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
    case conn.body_params do
      %{"user_id" => uid, "nickname" => nickname} ->
        #
        # TODO: Validate uid, nickname
        #
        Logger.debug "Nickname: #{nickname} - UserId: #{uid}"

        # TODO: Update the user nickname

        create_channel conn, "abcd", nickname

      %{"nickname" => nickname} ->
        #
        # TODO: Validate nickname
        #
        Logger.debug "Nickname: #{nickname}"

        # TODO: Create the user

        create_channel conn, "abcd", nickname

      _ ->
        Logger.debug "Error, no nickname provided"
        data = %{
          status: "400",
          msg: "Missing 'nickname' parameter",
        }
        conn
        |> put_resp_header("Access-Control-Allow-Origin", "*")
        |> put_resp_header("Content_Type", "application/json;charset=UTF-8")
        |> send_resp(400, Jason.encode!(data))
        |> halt()
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end


  # -------------------------------------------------------------
  # Private
  # -------------------------------------------------------------

  defp create_channel(conn, user_id, nickname) do
    #
    # TODO: Create the channel
    #
    data = %{
      channel_id: "abcd",
      owner_id: user_id,
      owner_nickname: nickname,
    }
    json = Jason.encode! data

    conn
    |> put_resp_header("Access-Control-Allow-Origin", "*")
    |> put_resp_header("Content_Type", "application/json;charset=UTF-8")
    |> send_resp(200, json)
  end
end

