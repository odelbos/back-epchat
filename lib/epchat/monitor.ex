defmodule Epchat.Monitor do
  require Logger
  use GenServer
  alias Epchat.Db
  alias Epchat.Channels

  def start_link(state) do
    GenServer.start_link __MODULE__, state, name: __MODULE__
  end

  def init(state) do
    schedule_users_check state.users_interval
    schedule_channels_check state.channels_interval
    {:ok, state}
  end

  # -----

  # Search all inactive users and cleanup database
  def handle_info(:check_users_activity, state) do
    now = :os.system_time :second
    since = now - state.users_limit
    case Db.Users.all_inactive_since since do
      {:error, reason} ->
        Logger.debug "Cannot get inactive users: #{reason}"
      {:ok, []} -> :ok
      {:ok, users} -> cleanup_users users
    end
    {:noreply, state}
  end

  # -----

  # Search all inactive channels and cleanup database
  def handle_info(:check_channels_activity, state) do
    now = :os.system_time :second
    since = now - state.channels_limit
    case Db.Channels.all_inactive_since since do
      {:error, reason} ->
        Logger.debug "Cannot get inactive channels: #{reason}"
      {:ok, []} -> :ok
      {:ok, users} -> cleanup_channels users
    end
    {:noreply, state}
  end

  # -----

  defp schedule_users_check(interval) do
    :timer.send_interval (interval * 1000), :check_users_activity
  end

  defp cleanup_users([]), do: :ok

  defp cleanup_users([user | tail]) do
    Logger.debug "Delete user: #{user.id}"
    Db.Users.delete user.id
    cleanup_users tail
  end

  # -----

  defp schedule_channels_check(interval) do
    :timer.send_interval (interval * 1000), :check_channels_activity
  end

  defp cleanup_channels([]), do: :ok

  defp cleanup_channels([channel | tail]) do
    Logger.debug "Delete channel: #{channel.id}"
    Channels.Manager.close_channel channel.id, :ch_no_activity
    cleanup_channels tail
  end
end
