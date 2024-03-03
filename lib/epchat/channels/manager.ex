defmodule Epchat.Channels.Manager do
  require Logger
  use GenServer
  alias Epchat.Db
  alias Epchat.Channels

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  # -----

  def create_channel(user) do
    case Db.Channels.create user do
      {:error, reason} -> {:error, reason}
      {:ok, nil} -> {:ok, nil}
      {:ok, channel} ->
        Logger.debug "Created channel: #{channel.id} - Owner: #{user.id}"
        {:ok, channel}
    end
  end

  def close_channel(channel_id, reason) do
    GenServer.cast __MODULE__, {:close_channel, channel_id, reason}
  end

  def update_channel_activity(channel_id) do
    case Db.Channels.update_last_activity_at channel_id do
      {:error, reason} ->
        Logger.debug "Cannot update channel last activity: #{channel_id} - #{reason}"
      {:ok, nil} ->
        Logger.debug "Cannot update channel last activity: #{channel_id} - not found"
      {:ok, _channel} -> :ok
    end
  end

  # -----

  def handle_cast({:close_channel, channel_id, reason}, state) do
    close channel_id, reason
    {:noreply, state}
  end

  # ---------------------------------------------------------
  # Private
  # ---------------------------------------------------------

  defp close(channel_id, reason) do
    case Db.Channels.get channel_id do
      {:ok, nil} -> :ok
      {:error, reason} -> {:error, reason}
      {:ok, channel} -> do_close channel, reason
    end
  end

  defp do_close(channel, reason) do
    case Db.Memberships.all_members channel.id do
      {:error, reason} -> {:error, reason}

      {:ok, []} ->
        #
        # TODO: Normally this case should never happens?
        #
        case Db.Channels.delete channel.id do
          :ok -> :ok
          _ -> Logger.debug "Cannot delete channel: #{channel.id}"
        end
        :ok

      {:ok, members} ->
        # For all members, remove the channel from the state of the websocket handler
        for %{pid: spid} <- members do
          pid = Epchat.Utils.string_to_pid spid
          send pid, {:channel_closed, channel.id}
        end

        # Broadcast to all members that the channel is closed
        Channels.broadcast channel, members, :ch_closed, %{reason: reason}

        # Clean up database
        # NOTE: Don't need to handle anything, if there is an error the Db.*
        # modules will log it.
        Db.Tokens.delete_all_for_channel channel.id
        Db.Memberships.delete_all_members channel.id
        Db.Channels.delete channel.id

        Logger.debug "Channel closed: #{channel.id}"
        :ok
    end
  end
end
