defmodule Epchat.Channels.Monitor do
  require Logger
  use GenServer
  alias Epchat.Db
  alias Epchat.Channels

  def start_link(channel_id) do
    name = {:via, Registry, {:channels, channel_id}}
    GenServer.start_link __MODULE__, %{channel_id: channel_id}, name: name
  end

  def init(state) do
    schedule()
    {:ok, state}
  end

  # NOTE: Don't know why this function is never call when
  # the dynamic supervisor call terminate_child/2
  #
  # def terminate(reason, state) do
  #   Logger.debug "Terminating channel monitor: #{state.channel_id} - #{inspect reason}"
  #   :ok
  # end

  # -----

  def child_spec(channel_id) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [channel_id]},
      restart: :transient
    }
  end

  # -----

  def handle_info(:update_activity, state) do
    case Db.Channels.update_last_activity_at state.channel_id do
      {:error, reason} ->
        Logger.debug "Cannot update channel last activity: #{state.channel_id} - #{reason}"
      {:ok, nil} ->
        Logger.debug "Cannot update channel last activity: #{state.channel_id} - not found"
      {:ok, _channel} -> :ok
    end
    {:noreply, state}
  end

  def handle_info(:check_activity, state) do
    case Db.Channels.get state.channel_id do
      {:error, reason} ->
        Logger.debug "Cannot get channel: #{state.channel_id} - #{reason}"
      {:ok, nil} ->
        Logger.debug "Cannot get channel: #{state.channel_id} - not found"
      {:ok, channel} ->
        now = :os.system_time :second
        conf = Application.fetch_env! :epchat, :channels
        if now > channel.last_activity_at + conf.inactivity_limit do
          Logger.debug "Channel #{channel.id} inactive since #{trunc(conf.inactivity_limit / 60)}mn"
          Channels.Manager.close_channel channel.id, :ch_no_activity
        end
    end
    {:noreply, state}
  end

  # -----

  defp schedule() do
    # TODO: Move interval delay constant into config
    :timer.send_interval 30_000, :check_activity
  end
end
