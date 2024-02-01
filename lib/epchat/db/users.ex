defmodule Epchat.Db.Users do
  require Logger
  alias Epchat.Db.Db
  alias Epchat.Db.Utils

  def create(nickname) do
    query = """
      INSERT INTO 'users' (id, nickname, last_activity_at) VALUES (?, ?, ?); 
    """
    case validate_nickname nickname do
      true ->
        # -----------------------------------------Duplicate-Code-------- DUP-001
        # TODO: Check that id does not already exists
        conf = Application.fetch_env! :epchat, :db
        id = Epchat.Utils.generate_b62 conf.ids_length
        case Db.execute query, [id, nickname, :os.system_time(:second)] do
          {:ok, [], []} -> get id
          {:error, reason} ->
            Logger.debug "Cannot create user, reason: #{reason}"
            {:error, reason}
        end
        # ------------------------------------------------------------- / DUP-001
      false ->
        {:error, :bad_params}
    end
  end

  def create_or_update(user_id, nickname) do
    case get user_id do
      {:error, reason} -> {:error, reason}
      {:ok, nil} ->
        create nickname
      {:ok, _user} ->
        update user_id, nickname
    end
  end

  def get(id) do
    query = """
      SELECT id, nickname, last_activity_at FROM 'users' WHERE id=?; 
    """
    # -----------------------------------------Duplicate-Code-------- DUP-002
    case Db.execute query, [id] do
      {:ok, [], _} -> {:ok, nil}
      {:ok, rows, fields} ->
        [first | _rest] = Utils.reshape_as_list_of_map rows, fields
        {:ok, first}
      {:error, reason} ->
        Logger.debug "Cannot get user, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-002
  end

  def all() do
    query = """
      SELECT id, nickname, last_activity_at FROM 'users'; 
    """
    # -----------------------------------------Duplicate-Code-------- DUP-003
    case Db.execute query do
      {:ok, [], _} -> {:ok, []}
      {:ok, rows, fields} ->
        {:ok, Utils.reshape_as_list_of_map(rows, fields)}
      {:error, reason} ->
        Logger.debug "Cannot get all users, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-003
  end

  def all_inactive_since(since) do
    query = """
      SELECT id, nickname, last_activity_at FROM 'users' WHERE last_activity_at <= ?; 
    """
    # -----------------------------------------Duplicate-Code-------- DUP-003
    case Db.execute query, [since] do
      {:ok, [], _} -> {:ok, []}
      {:ok, rows, fields} ->
        {:ok, Utils.reshape_as_list_of_map(rows, fields)}
      {:error, reason} ->
        Logger.debug "Cannot get all users, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-003
  end

  def update(id, nickname) do
    query = """
      UPDATE 'users' SET nickname=?, last_activity_at=? WHERE id=?; 
    """
    case validate_nickname nickname do
      true ->
        # -----------------------------------------Duplicate-Code-------- DUP-004
        case Db.execute query, [nickname, :os.system_time(:second), id] do
          {:ok, [], []} -> get id
          {:error, reason} ->
            Logger.debug "Cannot update user, reason: #{reason}"
            {:error, reason}
        end
        # ------------------------------------------------------------- / DUP-004
      false ->
        {:error, :bad_params}
    end
  end

  def update_last_activity_at(id) do
    query = """
      UPDATE 'users' SET last_activity_at=? WHERE id=?; 
    """
    # TODO: -----------------------------------Duplicate-Code-------- DUP-004
    case Db.execute query, [:os.system_time(:second), id] do
      {:ok, [], []} -> get id
      {:error, reason} ->
        Logger.debug "Cannot update user, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-004
  end

  # -----

  defp validate_nickname(nickname) do
    String.length(nickname) > 1 and String.length(nickname) < 15
  end
end
