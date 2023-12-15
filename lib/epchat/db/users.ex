defmodule Epchat.Db.Users do
  require Logger
  alias Epchat.Db.Db
  alias Epchat.Db.Utils

  def create(nickname) do
    query = """
      INSERT INTO 'users' (id, nickname) VALUES (?, ?); 
    """
    case validate_nickname nickname do
      true ->
        # -----------------------------------------Duplicate-Code-------- DUP-001
        # TODO: Check that id does not already exists
        conf = Application.fetch_env! :epchat, :db
        id = Epchat.Utils.generate_b62 conf.ids_length
        case Db.execute query, [id, nickname] do
          {:ok, [], []} -> get id
          _ -> :error
        end
        # ------------------------------------------------------------- / DUP-001
      false ->
        :param_error
    end
  end

  def get(id) do
    query = """
      SELECT id, nickname FROM 'users' WHERE id=?; 
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
      SELECT id, nickname FROM 'users'; 
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

  def update(id, nickname) do
    query = """
      UPDATE 'users' SET nickname=? WHERE id=?; 
    """
    case validate_nickname nickname do
      true ->
        # -----------------------------------------Duplicate-Code-------- DUP-004
        case Db.execute query, [nickname, id] do
          {:ok, [], []} -> get id
          {:error, reason} ->
            Logger.debug "Cannot update user, reason: #{reason}"
            {:error, reason}
        end
        # ------------------------------------------------------------- / DUP-004
      false ->
        :param_error
    end
  end

  # -----

  defp validate_nickname(nickname) do
    String.length(nickname) > 1 and String.length(nickname) < 15
  end
end
