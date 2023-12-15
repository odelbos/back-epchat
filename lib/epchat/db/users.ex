defmodule Epchat.Db.Users do
  require Logger
  alias Epchat.Db.Db
  alias Epchat.Db.Utils

  def create(nickname) do
    query = """
      INSERT INTO 'users' (id, nickname) VALUES (?, ?); 
    """
    # TODO: Get the ids length from config
    # TODO: Check that id does not already exists
    id = Epchat.Utils.generate_b62 15

    case Db.execute query, [id, nickname] do
      {:ok, [], []} -> get id
      _ -> :error
    end
  end

  def get(id) do
    query = """
      SELECT id, nickname FROM 'users' WHERE id=?; 
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
      SELECT id, nickname FROM 'users'; 
    """
    case Db.execute query do
      {:ok, [], _} -> []
      {:ok, rows, fields} ->
        Utils.reshape_as_list_of_map rows, fields
      _ -> :error
    end
  end

  def update(id, nickname) do
    query = """
      UPDATE 'users' SET nickname=? WHERE id=?; 
    """
    case Db.execute query, [nickname, id] do
      {:ok, [], []} -> get id
      {:error, reason} ->
        Logger.debug "Cannot update user, reason: #{reason}"
        {:error, reason}
    end
  end
end
