defmodule Epchat.CleanupMonitor do
  require Logger
  use GenServer
  alias Epchat.Db

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(state) do
    schedule()
    {:ok, state}
  end

  # -----

  # Search all inactive users and cleanup database
  def handle_info(:check_users_activity, state) do
    conf = Application.fetch_env! :epchat, :cleanup
    now = :os.system_time :second
    since = now - conf.user_inactivity_limit
    case Db.Users.all_inactive_since since do
      {:error, reason} ->
        Logger.debug "Cannot get inactive users: #{reason}"
      {:ok, []} -> :ok
      {:ok, users} -> cleanup_users users
    end
    {:noreply, state}
  end

  # -----

  defp schedule() do
    conf = Application.fetch_env! :epchat, :cleanup
    :timer.send_interval (conf.check_user_activity_interval * 1000), :check_users_activity
  end

  defp cleanup_users([]), do: :ok

  defp cleanup_users([user | tail]) do
    Logger.debug "Delete user: #{user.id}"
    Db.Users.delete user.id
    cleanup_users tail
  end
end
