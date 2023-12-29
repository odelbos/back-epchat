defmodule Epchat.Db.Tokens do
  require Logger
  alias Epchat.Db.Db
  alias Epchat.Db.Utils

  def create(channel_id) do
    query = """
      INSERT INTO 'tokens' (id, channel_id, created_at) VALUES (?, ?, ?); 
    """
    #
    # TODO: Validate channel_id? (database FK will do it for us)
    # Only validate the channel_id format?
    #
    # -----------------------------------------Duplicate-Code-------- DUP-001
    # TODO: Check that id does not already exists
    conf = Application.fetch_env! :epchat, :db
    id = Epchat.Utils.generate_b62 conf.ids_length
    case Db.execute query, [id, channel_id, :os.system_time(:second)] do
      {:ok, [], []} -> get id
      {:error, reason} ->
        Logger.debug "Cannot create token, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-001
  end

  def get(id) do
    query = """
      SELECT id, channel_id, created_at FROM 'tokens' WHERE id=?; 
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
      SELECT id, channel_id, created_at FROM 'tokens'; 
    """
    # -----------------------------------------Duplicate-Code-------- DUP-003
    case Db.execute query do
      {:ok, [], _} -> {:ok, []}
      {:ok, rows, fields} ->
        {:ok, Utils.reshape_as_list_of_map(rows, fields)}
      {:error, reason} ->
        Logger.debug "Cannot get all tokens, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-003
  end

  # -----

  def delete(id) do
    query = """
      DELETE FROM 'tokens' WHERE id=?; 
    """
    # TODO: -----------------------------------Duplicate-Code-------- DUP-005
    case Db.execute query, [id] do
      {:ok, [], _} -> :ok
      {:error, reason} ->
        Logger.debug "Cannot delete token, reason: #{reason}"
        {:error, reason}
    # ------------------------------------------------------------- / DUP-005
    end
  end

  def delete_all_for_channel(channel_id) do
    query = """
      DELETE FROM 'tokens' WHERE channel_id=?; 
    """
    # TODO: -----------------------------------Duplicate-Code-------- DUP-005
    case Db.execute query, [channel_id] do
      {:ok, [], _} -> :ok
      {:error, reason} ->
        Logger.debug "Cannot delete all tokens, reason: #{reason}"
        {:error, reason}
    # ------------------------------------------------------------- / DUP-005
    end
  end

  # -----

  def valid?(token) do
    if :os.system_time(:second) > token.created_at + 60 do
      delete token.id
      false
    else
      true
    end
  end
end
