defmodule Epchat.Db.Schema do
  require Logger

  def init(conn) do
    create_users_table conn
    create_channels_table conn
  end

  def create_users_table(conn) do
    query = """
      CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          nickname TEXT NOT NULL
      );
    """
    case Epchat.Db.Db.query conn, query do
      {:error, reason} ->
        Logger.debug "Cannot create 'users' table, reason: #{reason}"
        raise "Cannot create 'users' table"
      _ -> :ok
    end
  end

  def create_channels_table(conn) do
    query = """
      CREATE TABLE IF NOT EXISTS channels (
          id text PRIMARY KEY,
          owner_id TEXT NOT NULL,
          last_activity_at INTEGER NOT NULL,
          FOREIGN KEY (owner_id) REFERENCES users (id)
      );
    """
    case Epchat.Db.Db.query conn, query do
      {:error, reason} ->
        Logger.debug "Cannot create 'channels' table, reason: #{reason}"
        raise "Cannot create 'channels' table"
      _ -> :ok
    end
  end
end
