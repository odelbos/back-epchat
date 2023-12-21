defmodule Epchat.Channels do
  require Logger
  alias Epchat.Db
  alias Epchat.Channels

  def join(channel_id, user_id, pid) do
    case get_channel_and_user channel_id, user_id, true do
      {:error, reason} -> {:error, reason}
      {:not_found, reason} -> {:not_found, reason}

      {:not_member, channel, user} ->
        case Db.Memberships.create channel, user, pid do
          {:error, reason} -> {:error, reason}
          {:ok, nil} -> {:error, :membership_not_created}
          {:ok, _membership} -> do_join channel, user, pid
        end

      {:ok, channel, user, _membership} ->
        case Db.Memberships.update_pid channel.id, user.id, pid do
          {:error, reason} -> {:error, reason}
          {:ok, nil} -> {:error, :membership_not_exists}
          {:ok, _membership} -> do_join channel, user, pid
        end
    end
  end

  defp do_join(channel, user, pid) do
    case Db.Memberships.all_members channel.id do
      {:error, reason} -> {:error, reason}
      {:ok, members} ->
        bmsg = %{
          member: %{id: user.id, nickname: user.nickname},
        }

        broadcast channel, members, :ch_member_join, bmsg, pid

        members_without_pid = Enum.map(members, fn(m) ->
          %{id: id, nickname: nickname} = m
          %{id: id, nickname: nickname}
        end)

        msg = %{
          members: members_without_pid,
        }
        {:ok, msg}
    end
  end

  # -----

  def members(channel_id, user_id) do
    case get_channel_and_user channel_id, user_id, true do
      {:error, reason} -> {:error, reason}
      {:not_found, reason} -> {:not_found, reason}
      {:not_member, _, _} -> {:not_member, :not_member}

      {:ok, channel, _user, _membership} ->
        case Db.Memberships.all_members channel.id do
          {:error, reason} -> {:error, reason}
          {:ok, members} ->
            members_without_pid = Enum.map(members, fn(m) ->
              %{id: id, nickname: nickname} = m
              %{id: id, nickname: nickname}
            end)

            msg = %{
              members: members_without_pid,
            }
            {:ok, msg}
        end
    end
  end

  # -----

  def message(channel_id, user_id, msg) do
    case get_channel_and_user channel_id, user_id, true do
      {:error, reason} -> {:error, reason}
      {:not_found, reason} -> {:not_found, reason}
      {:not_member, _, _} -> {:not_member, :not_member}

      {:ok, channel, user, _membership} ->
        case Db.Memberships.all_members channel_id do
          {:error, reason} -> {:error, reason}

          {:ok, members} ->
            data = %{
              from: %{id: user_id, nickname: user.nickname},
              msg: msg,
              at: :os.system_time(:second),
            }

            # Update channel activity
            Channels.Manager.update_channel_activity channel_id

            # TODO: Do not broadcast the msg to the sender?
            broadcast channel, members, :ch_msg, data

            :ok
        end
    end
  end

  # -----

  def leave(channel_id, user_id) do
    case get_channel_and_user channel_id, user_id, true do
      {:error, reason} -> {:error, reason}
      {:not_found, reason} -> {:not_found, reason}
      {:not_member, _, _} -> {:not_member, :not_member}

      {:ok, channel, user, membership} ->
        do_leave channel, user, membership
        Logger.debug "User #{user.id} left channel: #{channel.id}"
        #
        # TODO: What if now there isn't anymore channel member?
        #
    end
  end

  defp do_leave(channel, user, _membership) do
    case Db.Memberships.delete_member channel.id, user.id do
      {:error, reason} -> {:error, reason}

      :ok ->
        # Broadcast to all channel members a ch_member_leave event
        case Db.Memberships.all_members channel.id do
          {:error, reason} -> {:error, reason}
          {:ok, []} -> :ok
          {:ok, members} ->
            msg = %{
              user: %{id: user.id, nickname: user.nickname},
            }
            broadcast channel, members, :ch_member_leave, msg
            :ok
        end
    end
  end

  # -----

  def broadcast(channel, members, event, msg, from) do
    data = %{
      channel_id: channel.id,
      event: event,
      data: msg,
    }
    {_, json} = Jason.encode_to_iodata data    # TODO: Handle encoding error
    for %{pid: spid} <- members do
      pid = Epchat.Utils.string_to_pid spid
      if from == nil or pid != from do
        # TODO: Explore using a Registry instead of saving pid in db
        if Process.alive? pid do
          send pid, {:push, :text, json}
        end
      end
    end
  end

  def broadcast(channel, members, event, msg) do
    broadcast channel, members, event, msg, nil
  end


  # -------------------------------------------------
  # Private
  # -------------------------------------------------

  defp get_channel_and_user(channel_id, user_id, include_membership \\ false) do
    case [Db.Channels.get(channel_id), Db.Users.get(user_id)] do
      [{:error, r1}, {:error, r2}] -> {:error, r1 <> " - " <> r2}
      [{:error, r}, {_, _}] -> {:error, r}
      [{_, _}, {:error, r}] -> {:error, r}

      [{:ok, nil}, {:ok, nil}] -> {:not_found, :channel_and_user}
      [{:ok, nil}, {:ok, _}] -> {:not_found, :channel}
      [{:ok, _}, {:ok, nil}] -> {:not_found, :user}

      [{:ok, channel}, {:ok, user}] ->
        case include_membership do
          true when is_boolean(include_membership) ->
            case Db.Memberships.get channel_id, user_id do
              {:error, reason} -> {:error, reason}
              {:ok, nil} -> {:not_member, channel, user}
              {:ok, membership} ->
                {:ok, channel, user, membership}
            end
          _ ->
            {:ok, channel, user}
        end
    end
  end
end
