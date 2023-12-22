import Config

# For production
# config :logger, level: :warning

config :epchat,
  db: %{
    file: ":memory:",
    ids_length: 15,
  },
  channels: %{
    inactivity_interval: 300,     # 5mn In seconds
    inactivity_limit: 600         # 10mn in sseconds
  }
