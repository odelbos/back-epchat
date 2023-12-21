defmodule Epchat.Channels.Manager do
  require Logger
  use GenServer
  alias Epchat.Channels

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  # -----

  def close_channel(channel_id, reason) do
    GenServer.cast __MODULE__, {:close_channel, channel_id, reason}
  end

  def start_channel_monitor(channel_id) do
    case Channels.Supervisor.start_channel_monitor channel_id do
      {:ok, _pid} ->
        Logger.debug "Started monitoring channel: #{channel_id}"
        :ok
      {:error, error} ->
        Logger.debug "Cannot start monitoring channel: #{channel_id} - #{error}"
        :error
    end
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
    Channels.close channel_id, reason
    stop_channel_monitor channel_id
    {:noreply, state}
  end

  # -----

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
end
