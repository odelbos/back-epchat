defmodule Epchat.Db.Schema do
  require Logger
  alias Epchat.Db.Db

  def init(conn) do
    create_users_table conn
    create_channels_table conn
    create_memberships_table conn
    create_tokens_table conn
  end

  def create_users_table(conn) do
    query = """
      CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          nickname TEXT NOT NULL,
          last_activity_at INTEGER NOT NULL
      );
    """
    case Db.query conn, query do
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
    case Db.query conn, query do
      {:error, reason} ->
        Logger.debug "Cannot create 'channels' table, reason: #{reason}"
        raise "Cannot create 'channels' table"
      _ -> :ok
    end
  end

  defp create_memberships_table(conn) do
    query = """
      CREATE TABLE IF NOT EXISTS memberships (
          channel_id text TEXT,
          user_id TEXT,
          pid TEXT NOT NULL,
          joined_at INTEGER NOT NULL,
          PRIMARY KEY (channel_id, user_id),
          FOREIGN KEY (channel_id) REFERENCES channels (id),
          FOREIGN KEY (user_id) REFERENCES users (id)
      );
    """
    case Db.query conn, query do
      {:error, reason} ->
        Logger.debug "Cannot create 'memberships' table, reason: #{reason}"
        raise "Cannot create 'memberships' table"
      _ -> :ok
    end
  end

  def create_tokens_table(conn) do
    query = """
      CREATE TABLE IF NOT EXISTS tokens (
          id text PRIMARY KEY,
          channel_id TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (channel_id) REFERENCES channels (id)
      );
    """
    case Db.query conn, query do
      {:error, reason} ->
        Logger.debug "Cannot create 'tokens' table, reason: #{reason}"
        raise "Cannot create 'tokens' table"
      _ -> :ok
    end
  end
end
