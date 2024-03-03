import Config

config :epchat,
  bandit: %{
    ip: {0, 0, 0, 0},
    port: 4000,
  },
  db: %{
    file: ":memory:",
    ids_length: 15,
  },
  channels: %{
    members_limit: 10,
    token_life_time: 300,         # 5mn in seconds
  },
  monitor: %{
    users_inactivity_check_interval: 10,          # In seconds
    users_inactivity_limit: 180,                  # 3mn in seconds
    channels_inactivity_check_interval: 30,       # In seconds
    channels_inactivity_limit: 60,                # 1mn in seconds
  }

import_config "#{config_env()}.exs"
