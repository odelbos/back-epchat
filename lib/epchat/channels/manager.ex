defmodule Epchat.Channels.Manager do
  require Logger
  use GenServer
  alias Epchat.Db
  alias Epchat.Channels

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  # -----

  def create_channel(user) do
    case Db.Channels.create user do
      {:error, reason} -> {:error, reason}
      {:ok, nil} -> {:ok, nil}
      {:ok, channel} ->
        Logger.debug "Created channel: #{channel.id} - Owner: #{user.id}"
        start_channel_monitor channel.id
        {:ok, channel}
    end
  end

  def close_channel(channel_id, reason) do
    GenServer.cast __MODULE__, {:close_channel, channel_id, reason}
  end

  def update_channel_activity(channel_id) do
    case lookup_channel_monitor channel_id do
      {:ok, monitor_pid} ->
        send monitor_pid, :update_activity
        Logger.debug "Updated activity for channel: #{channel_id}"
        :ok
      _ ->
        Logger.debug "Cannot update channel activity: #{channel_id}"
        :error
    end
  end

  # -----

  def handle_cast({:close_channel, channel_id, reason}, state) do
    # Channels.close channel_id, reason
    close channel_id, reason
    stop_channel_monitor channel_id
    {:noreply, state}
  end


  # ---------------------------------------------------------
  # Private
  # ---------------------------------------------------------

  defp start_channel_monitor(channel_id) do
    case Channels.Supervisor.start_channel_monitor channel_id do
      {:ok, _pid} ->
        Logger.debug "Started monitoring channel: #{channel_id}"
        :ok
      {:error, error} ->
        Logger.debug "Cannot start monitoring channel: #{channel_id} - #{error}"
        :error
    end
  end

  defp stop_channel_monitor(channel_id) do
    case lookup_channel_monitor channel_id do
      {:ok, monitor_pid} ->
        case Channels.Supervisor.stop_channel_monitor monitor_pid do
          :ok ->
            Logger.debug "Stopped monitoring channel: #{channel_id}"
            :ok
          {:error, :not_found} ->
            Logger.debug "Cannot stop monitoring channel: #{channel_id} - monitor not found"
            :error
        end
      _ -> :error
    end
  end

  defp lookup_channel_monitor(channel_id) do
    case Registry.lookup :channels, channel_id do
      [{pid, _}] -> {:ok, pid}
      [] ->
        Logger.debug "Cannot lookup channel monitor: #{channel_id}"
        {:error, :not_found}
    end
  end

  # -----

  defp close(channel_id, reason) do
    case Db.Channels.get channel_id do
      {:ok, nil} -> :ok
      {:error, reason} -> {:error, reason}
      {:ok, channel} -> do_close channel, reason
    end
  end

  defp do_close(channel, reason) do
    case Db.Memberships.all_members channel.id do
      {:error, reason} -> {:error, reason}

      {:ok, []} ->
        #
        # TODO: Normally this case should never happens?
        #
        case Db.Channels.delete channel.id do
          :ok -> :ok
          _ -> Logger.debug "Cannot delete channel: #{channel.id}"
        end
        :ok

      {:ok, members} ->
        # For all members, remove the channel from the state of the websocket handler
        for %{pid: spid} <- members do
          pid = Epchat.Utils.string_to_pid spid
          send pid, {:channel_closed, channel.id}
        end

        # Broadcast to all members that the channel is closed
        Channels.broadcast channel, members, :ch_closed, %{reason: reason}

        # Clean up database
        case Db.Memberships.delete_all_members channel.id do
          :ok -> :ok
          _ ->
            Logger.debug "Cannot delete all channel members: #{channel.id}"
        end
        case Db.Channels.delete channel.id do
          :ok -> :ok
          _ ->
            Logger.debug "Cannot delete channel: #{channel.id}"
        end

        Logger.debug "Channel closed: #{channel.id}"
        :ok
    end
  end
end
