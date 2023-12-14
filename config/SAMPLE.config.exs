import Config

# For production
# config :logger, level: :warning

config :epchat,
  db: %{
    file: "/.../.../epchat.sqlite",
    # file: ":memory:",
    ids_length: 15,
  }
