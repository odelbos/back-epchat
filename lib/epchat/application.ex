defmodule Epchat.Application do
  @moduledoc false

  require Logger
  use Application

  @impl true
  def start(_type, _args) do

    db_conf = Application.fetch_env! :epchat, :db
    Logger.debug "DB file: #{db_conf.file}"

    bandit_conf = Application.fetch_env! :epchat, :bandit

    children = [
      {Bandit, plug: Epchat.Router, ip: bandit_conf.ip, port: bandit_conf.port},
      {Epchat.Db.Db, %{file: db_conf.file}},
      {Epchat.Channels.Manager, []},
      {Registry, [keys: :unique, name: :channels]},
      Epchat.Channels.Supervisor,
      {Epchat.CleanupMonitor, []},
    ]

    opts = [strategy: :one_for_one, name: Epchat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
