defmodule Epchat.Db.Memberships do
  require Logger
  alias Epchat.Db.Db
  alias Epchat.Db.Utils

  def create(channel, user, pid) do
    # TODO: Explore saving the pid in a Registry, instead of storing it in db
    spid = Epchat.Utils.pid_to_string pid

    query = """
      INSERT INTO 'memberships' (channel_id, user_id, pid, joined_at)
        VALUES (?, ?, ?, ?); 
    """
    # TODO: ----------------------------------Duplicate-Code-------- DUP-001
    params = [channel.id, user.id, spid, :os.system_time(:millisecond)]
    case Db.execute query, params do
      {:ok, [], []} -> get channel.id, user.id
      {:error, reason} ->
        Logger.debug "Cannot create membership, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-001
  end

  def get(channel_id, user_id) do
    query = """
      SELECT channel_id, user_id, pid, joined_at
        FROM 'memberships' WHERE channel_id=? AND user_id=?; 
    """
    # TODO: ----------------------------------Duplicate-Code-------- DUP-002
    case Db.execute query, [channel_id, user_id] do
      {:ok, [], _} -> {:ok, nil}
      {:ok, [row | _rest], fields} ->
        {:ok, Utils.reshape_row_as_map(row, fields)}
      {:error, reason} ->
        Logger.debug "Cannot get membership, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-002
  end

  # -----

  def update_pid(channel_id, user_id, pid) do
    query = """
      UPDATE 'memberships' SET pid=? WHERE channel_id=? AND user_id=?; 
    """
    # TODO: Explore saving the pid in a Registry, instead of storing it in db
    spid = Epchat.Utils.pid_to_string pid

    # TODO: -----------------------------------Duplicate-Code-------- DUP-004
    case Db.execute query, [spid, channel_id, user_id] do
      {:ok, [], []} -> get channel_id, user_id
      {:error, reason} ->
        Logger.debug "Cannot update 'pid' membership, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-004
  end

  # -----

  def all_members(channel_id) do
    query = """
      SELECT u.id, u.nickname, cu.pid, cu.joined_at FROM 'memberships' AS cu
        INNER JOIN users AS u ON cu.user_id = u.id
        WHERE channel_id=?
        ORDER BY joined_at ASC
    """
    # TODO: ----------------------------------Duplicate-Code-------- DUP-003
    case Db.execute query, [channel_id] do
      {:ok, [], _} -> {:ok, []}
      {:ok, rows, fields} ->
        {:ok, Utils.reshape_as_list_of_map(rows, fields)}
      {:error, reason} ->
        Logger.debug "Cannot get all channel membership, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-003
  end

  # -----

  def delete_member(channel_id, user_id) do
    query = """
      DELETE FROM 'memberships' WHERE channel_id=? AND user_id=?; 
    """
    # TODO: -----------------------------------Duplicate-Code-------- DUP-005
    case Db.execute query, [channel_id, user_id] do
      {:ok, [], _} -> :ok
      {:error, reason} ->
        Logger.debug "Cannot delete membership, reason: #{reason}"
        {:error, reason}
    end
    # ------------------------------------------------------------- / DUP-005
  end

  def delete_all_members(channel_id) do
    query = """
      DELETE FROM 'memberships' WHERE channel_id=?; 
    """
    # TODO: -----------------------------------Duplicate-Code-------- DUP-005
    case Db.execute query, [channel_id] do
      # TODO: Duplicate code, start: DUP-003
      {:ok, [], _} -> :ok
      {:error, reason} ->
        Logger.debug "Cannot delete all memberships, reason: #{reason}"
        {:error, reason}
    # ------------------------------------------------------------- / DUP-005
    end
  end
end
