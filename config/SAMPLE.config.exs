import Config

# For production
# config :logger, level: :warning

config :epchat,
  bandit: %{
    ip: {0, 0, 0, 0},
    port: 4000,
  },
  db: %{
    file: ":memory:",
    ids_length: 15,
  },
  cleanup: %{
    check_user_activity_interval: 3600,       # 1h in seconds
    user_inactivity_limit: 3600 * 24 * 4,     # 5 days in seconds
  },
  channels: %{
    members_limit: 10,
    token_life_time: 300,         # 5mn in seconds
    inactivity_interval: 300,     # 5mn In seconds
    inactivity_limit: 600,        # 10mn in sseconds
  }
