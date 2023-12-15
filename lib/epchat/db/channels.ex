defmodule Epchat.Db.Channels do
  require Logger
  alias Epchat.Db.Db
  alias Epchat.Db.Utils

  def create(user) do
    query = """
      INSERT INTO 'channels' (id, owner_id, last_activity_at) VALUES (?, ?, ?); 
    """
    # -----------------------------------------Duplicate-Code-------- DUP-001
    # TODO: Check that id does not already exists
    conf = Application.fetch_env! :epchat, :db
    id = Epchat.Utils.generate_b62 conf.ids_length
    case Db.execute query, [id, user.id, :os.system_time(:second)] do
      {:ok, [], []} -> get id
      {:error, reason} ->
        Logger.debug "Cannot create channel, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-001
  end

  def get(id) do
    query = """
      SELECT id, owner_id, last_activity_at FROM 'channels' WHERE id=?; 
    """
    # -----------------------------------------Duplicate-Code-------- DUP-002
    case Db.execute query, [id] do
      {:ok, [], _} -> nil
      {:ok, rows, fields} ->
        [first | _rest] = Utils.reshape_as_list_of_map rows, fields
        first
      {:error, reason} ->
        Logger.debug "Cannot get channel, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-002
  end

  def all() do
    query = """
      SELECT id, owner_id, last_activity_at FROM 'channels'; 
    """
    # -----------------------------------------Duplicate-Code-------- DUP-003
    case Db.execute query do
      {:ok, [], _} -> []
      {:ok, rows, fields} ->
        Utils.reshape_as_list_of_map rows, fields
      {:error, reason} ->
        Logger.debug "Cannot get all channels, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-003
  end

  def update_last_activity_at(id) do
    query = """
      UPDATE 'channels' SET last_activity_at=? WHERE id=?; 
    """
    # -----------------------------------------Duplicate-Code-------- DUP-004
    case Db.execute query, [:os.system_time(:second), id] do
      {:ok, [], []} -> get id
      {:error, reason} ->
        Logger.debug "Cannot update channel, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-004
  end
end
