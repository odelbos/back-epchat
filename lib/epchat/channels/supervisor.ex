defmodule Epchat.Channels.Supervisor do
  require Logger
  use DynamicSupervisor

  def start_link(opts) do
    DynamicSupervisor.start_link __MODULE__, opts, name: __MODULE__
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init strategy: :one_for_one
  end

  def start_channel_monitor(channel_id) do
    spec = Epchat.Channels.Monitor.child_spec channel_id
    DynamicSupervisor.start_child __MODULE__, spec
  end

  def stop_channel_monitor(child_id) do
    DynamicSupervisor.terminate_child __MODULE__, child_id
  end
end
