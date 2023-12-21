defmodule Epchat.Channels.Monitor do
  require Logger
  use GenServer
  alias Epchat.Channels

  def start_link(channel_id) do
    name = {:via, Registry, {:channels, channel_id}}
    state = %{channel_id: channel_id, last_activity: :os.system_time(:second)}
    GenServer.start_link __MODULE__, state, name: name
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
    {:noreply, Map.put(state, :last_activity, :os.system_time(:second))}
  end

  def handle_info(:health, state) do
    %{channel_id: channel_id, last_activity: last_activity} = state
    now = :os.system_time :second
    conf = Application.fetch_env! :epchat, :channels
    if now > last_activity + conf.inactivity_limit do
      Logger.debug "Channel #{channel_id} inactive since #{trunc(conf.inactivity_limit / 60)}mn"
      Channels.Manager.close_channel channel_id, :ch_no_activity
    end
    {:noreply, state}
  end

  # -----

  defp schedule() do
    # TODO: Move interval delay constant into config
    :timer.send_interval 30_000, :health
  end
end
