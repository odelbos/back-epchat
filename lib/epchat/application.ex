defmodule Epchat.Application do
  @moduledoc false

  require Logger
  use Application

  @impl true
  def start(_type, _args) do

    conf = Application.fetch_env! :epchat, :db
    Logger.debug "DB file: #{conf.file}"

    children = [
      {Bandit, plug: Epchat.Router},
      {Epchat.Db.Db, %{file: conf.file}},
      {Epchat.Channels.Manager, []},
      {Registry, [keys: :unique, name: :channels]},
      Epchat.Channels.Supervisor,
      {Epchat.CleanupMonitor, []},
    ]

    opts = [strategy: :one_for_one, name: Epchat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
