defmodule Epchat.Application do
  @moduledoc false

  require Logger
  use Application

  @impl true
  def start(_type, _args) do
    db_conf = Application.fetch_env! :epchat, :db
    bandit_conf = Application.fetch_env! :epchat, :bandit
    monitor_conf = Application.fetch_env! :epchat, :monitor

    children = [
      {Bandit, plug: Epchat.Router, ip: bandit_conf.ip, port: bandit_conf.port},
      {Epchat.Db.Db, %{file: db_conf.file}},
      {Epchat.Channels.Manager, []},
      {Registry, [keys: :unique, name: :channels]},
      {Epchat.Monitor, %{
        users_interval: monitor_conf.users_inactivity_check_interval,
        users_limit: monitor_conf.users_inactivity_limit,
        channels_interval: monitor_conf.channels_inactivity_check_interval,
        channels_limit: monitor_conf.channels_inactivity_limit,
      }},
    ]

    opts = [strategy: :one_for_one, name: Epchat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
