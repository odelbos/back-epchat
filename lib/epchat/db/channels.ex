defmodule Epchat.Db.Channels do
  alias Epchat.Db.Db
  alias Epchat.Db.Utils

  def create(user) do
    query = """
      INSERT INTO 'channels' (id, owner_id, last_activity_at) VALUES (?, ?, ?); 
    """
    # TODO: Get the ids length from config
    # TODO: Check that id does not already exists
    id = Epchat.Utils.generate_b62 15

    case Db.execute query, [id, user.id, :os.system_time(:second)] do
      {:ok, [], []} -> get id
      _ -> :error
    end
  end

  def get(id) do
    query = """
      SELECT id, owner_id, last_activity_at FROM 'channels' WHERE id=?; 
    """
    case Db.execute query, [id] do
      {:ok, [], _} -> nil
      {:ok, rows, fields} ->
        [first | _rest] = Utils.reshape_as_list_of_map rows, fields
        first
      _ -> :error
    end
  end

  def all() do
    query = """
      SELECT id, owner_id, last_activity_at FROM 'channels'; 
    """
    case Db.execute query do
      {:ok, [], _} -> []
      {:ok, rows, fields} ->
        Utils.reshape_as_list_of_map rows, fields
      _ -> :error
    end
  end

  def update_last_activity_at(id) do
    query = """
      UPDATE 'channels' SET last_activity_at=? WHERE id=?; 
    """
    case Db.execute query, [:os.system_time(:second), id] do
      {:ok, [], []} -> get id
      _ -> :error
    end
  end
end
