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
        Logger.debug "Nickname: #{nickname} - UserId: #{uid}"
        case Epchat.Db.Users.update uid, nickname do
          {:error, _reason} ->
            send_500_internal_error conn, "Cannot update user"
          :param_error ->
            send_400_bad_params conn
          # TODO: This case is not managed correctly
          # {:ok, nil} ->
          #   :error
          {:ok, user} ->
            Logger.debug "Updated user: #{user.id}"
            create_channel conn, user
        end

      %{"nickname" => nickname} ->
        Logger.debug "Nickname: #{nickname}"
        case Epchat.Db.Users.create nickname do
          {:error, _reason} ->
            send_500_internal_error conn, "Cannot create user"
          :param_error ->
            send_400_bad_params conn
          {:ok, user} ->
            Logger.debug "Created user: #{user.id}"
            create_channel conn, user
        end
      _ ->
        send_400_bad_params conn
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end


  # -------------------------------------------------------------
  # Private
  # -------------------------------------------------------------
  defp create_channel(conn, user) do
    case Epchat.Db.Channels.create user do
      {:error, _reason} ->
        send_500_internal_error conn, "Cannot create channel"
      {:ok, nil} ->
        send_500_internal_error conn, "Cannot create channel"
      {:ok, channel} ->
        Logger.debug "Created channel: #{channel.id}"
        data = %{
          status: 200,
          user: %{
            id: user.id,
            nickname: user.nickname,
          },
          channel: %{
            id: channel.id,
            owner_id: channel.owner_id,
            members: [],
          }
        }
        send_with_status conn, 200, data
    end
  end

  # -----

  defp send_with_status(conn, status, data) do
    conn
    |> put_resp_header("Access-Control-Allow-Origin", "*")
    |> put_resp_header("Content_Type", "application/json;charset=UTF-8")
    |> send_resp(status, Jason.encode! data)
  end

  defp send_500_internal_error(conn, msg) do
    Logger.debug msg
    send_with_status conn, 500, %{status: 500, msg: msg}
  end

  defp send_400_bad_params(conn) do
    Logger.debug "Error, bad or missing parameter"
    data = %{status: 400, msg: "Error, bad or missing parameter"}
    send_with_status conn, 400, data
  end
end

