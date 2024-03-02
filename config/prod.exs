import Config

config :logger, level: :info

config :epchat,
  db: %{
    file: ":memory:",
    ids_length: 15,
  }
