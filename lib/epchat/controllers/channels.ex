defmodule Epchat.Controllers.Channels do
  require Logger
  import Plug.Conn
  alias Epchat.Db

  def create(conn, %{"user_id" => user_id, "nickname" => nickname} = _params) do
    Logger.debug "Nickname: #{nickname} - UserId: #{user_id}"
    case Db.Users.create_or_update user_id, nickname do
      {:error, reason} ->
        send_500_internal_error conn, reason, "Cannot update user"
      :param_error ->
        send_400_bad_params conn
      {:ok, nil} ->
        send_400_bad_params conn
      {:ok, user} ->
        Logger.debug "Updated user: #{user.id}"
        create_channel conn, user
    end
  end

  def create(conn, %{"nickname" => nickname} = _params) do
    Logger.debug "Nickname: #{nickname}"
    case Db.Users.create nickname do
      {:error, reason} ->
        send_500_internal_error conn, reason, "Cannot create user"
      :param_error ->
        send_400_bad_params conn
      {:ok, nil} ->
        send_400_bad_params conn
      {:ok, user} ->
        Logger.debug "Created user: #{user.id}"
        create_channel conn, user
    end
  end

  def create(conn, _params) do
    send_400_bad_params conn
  end

  # -----

  def join(conn, %{"channel_id" => channel_id, "user_id" => user_id, "nickname" => nickname} = _params) do
    Logger.debug "Nickname: #{nickname} - UserId: #{user_id}"
    case Epchat.Db.Users.create_or_update user_id, nickname do
      {:error, reason} ->
        send_500_internal_error conn, reason, "Cannot update user"
      :param_error ->
        send_400_bad_params conn
      {:ok, nil} ->
        send_400_bad_params conn
      {:ok, user} ->
        Logger.debug "Updated user: #{user.id}"
        join_channel conn, channel_id, user
    end
  end

  def join(conn, %{"channel_id" => channel_id, "nickname" => nickname} = _params) do
    Logger.debug "Nickname: #{nickname}"
    case Epchat.Db.Users.create nickname do
      {:error, reason} ->
        send_500_internal_error conn, reason, "Cannot update user"
      :param_error ->
        send_400_bad_params conn
      {:ok, nil} ->
        send_400_bad_params conn
      {:ok, user} ->
        Logger.debug "Updated user: #{user.id}"
        join_channel conn, channel_id, user
    end
  end

  def join(conn, _params) do
    send_400_bad_params conn
  end


  # -------------------------------------------------------------
  # Private
  # -------------------------------------------------------------
  defp create_channel(conn, user) do
    case Db.Channels.create user do
      {:error, reason} ->
        send_500_internal_error conn, reason, "Internal Server Error"
      {:ok, nil} ->
        send_500_internal_error conn, "Bad params", "Cannot create channel"
      {:ok, channel} ->
        Logger.debug "Created channel: #{channel.id} - Owner: #{user.id}"
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

  defp join_channel(conn, channel_id, user) do
    case Epchat.Db.Channels.get channel_id do
      {:error, reason} ->
        send_500_internal_error conn, reason, "Internal Server Error"
      {:ok, nil} ->
        send_400_bad_params conn           # Channel does not exists
      {:ok, channel} ->
        Logger.debug "Join channel: #{channel.id} - User: #{user.id}"
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

  defp send_500_internal_error(conn, reason, msg) do
    Logger.debug msg <> ", reason: #{reason}"
    send_with_status conn, 500, %{status: 500, msg: msg}
  end

  defp send_400_bad_params(conn) do
    Logger.debug "Error, bad or missing parameter"
    data = %{status: 400, msg: "Error, bad or missing parameter"}
    send_with_status conn, 400, data
  end
end
