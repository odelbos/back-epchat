defmodule Epchat.Db.Channels do
  require Logger
  alias Epchat.Db.Db
  alias Epchat.Db.Utils

  def create(user) do
    query = """
      INSERT INTO 'channels' (id, owner_id, last_activity_at) VALUES (?, ?, ?); 
    """
    # TODO: Get the ids length from config
    # TODO: Check that id does not already exists

    # -----------------------------------------Duplicate-Code-------- DUP-001
    id = Epchat.Utils.generate_b62 15
    case Db.execute query, [id, user.id, :os.system_time(:second)] do
      {:ok, [], []} -> get id
      _ -> :error
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
      _ -> :error
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
      _ -> :error
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
        Logger.debug "Cannot update user, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-004
  end
end
