defmodule Epchat.Db.Schema do
  require Logger

  def init(conn) do
    create_users_table conn
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
end
