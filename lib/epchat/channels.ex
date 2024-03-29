defmodule Epchat.Channels do
  require Logger
  alias Epchat.Db
  alias Epchat.Channels

  # NOTE: Only the channel admin (ie: the owner) can use the join/3 function
  def join(channel_id, user_id, pid) do
    case get_channel_and_user channel_id, user_id, true do
      {:error, reason} -> {:error, reason}
      {:not_found, reason} -> {:not_found, reason}

      {:not_member, channel, user} ->
        if channel.owner_id == user.id do
          case Db.Memberships.create channel, user, pid do
            {:error, reason} -> {:error, reason}
            {:ok, nil} -> {:error, :membership_not_created}
            {:ok, _membership} ->
              msg = %{
                members: [%{id: user.id, nickname: user.nickname}],
              }
              {:ok, msg}
          end
        else
          {:forbidden, :not_admin}
        end

      {:ok, channel, user, _membership} ->
        if channel.owner_id == user.id do
          case Db.Memberships.update_pid channel.id, user.id, pid do
            {:error, reason} -> {:error, reason}
            {:ok, nil} -> {:error, :membership_not_exists}
            {:ok, _membership} ->
              msg = %{
                members: [%{id: user.id, nickname: user.nickname}],
              }
              {:ok, msg}
          end
        else
          {:forbidden, :not_admin}
        end
    end
  end

  # -----

  def join_with_token(channel_id, token_id, user_id, pid) do
    case Epchat.Db.Tokens.get_for_channel token_id, channel_id do
      {:error, reason} -> {:error, reason}
      {:ok, nil} -> {:forbidden, :invalid_token}
      {:ok, token} ->
        if Db.Tokens.valid? token do
          # Token is one time usage
          Db.Tokens.delete token.id
          join_with_token_create_membership channel_id, user_id, pid
        else
          {:forbidden, :invalid_token}
        end
    end
  end

  defp join_with_token_create_membership(channel_id, user_id, pid) do
    case get_channel_and_user channel_id, user_id do
      {:error, reason} -> {:error, reason}
      {:not_found, reason} -> {:not_found, reason}

      {:ok, channel, user} ->
        case Db.Memberships.create channel, user, pid do
          {:error, reason} -> {:error, reason}
          {:ok, nil} -> {:error, :membership_not_created}
          {:ok, _membership} -> do_join_with_token channel, user, pid
        end
    end
  end

  defp do_join_with_token(channel, user, pid) do
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
      {:not_member, _, _} -> {:forbidden, :not_member}

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
      {:not_member, _, _} -> {:forbidden, :not_member}

      {:ok, channel, user, _membership} ->
        case Db.Memberships.all_members channel_id do
          {:error, reason} -> {:error, reason}

          {:ok, members} ->
            data = %{
              from: %{id: user_id, nickname: user.nickname},
              msg: msg,
              at: :os.system_time(:second),
            }

            # TODO: Do not broadcast the msg to the sender?
            broadcast channel, members, :ch_msg, data

            # Update activities
            Channels.Manager.update_channel_activity channel_id
            Db.Users.update_last_activity_at user_id
            :ok
        end
    end
  end

  # -----

  def leave(channel_id, user_id) do
    case get_channel_and_user channel_id, user_id, true do
      {:error, reason} -> {:error, reason}
      {:not_found, reason} -> {:not_found, reason}
      {:not_member, _, _} -> {:forbidden, :not_member}

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

  def adm_request_invit_link(channel_id, user_id) do
    case get_channel_and_user channel_id, user_id, true do
      {:error, reason} -> {:error, reason}
      {:not_found, reason} -> {:not_found, reason}
      {:not_member, _, _} -> {:forbidden, :not_member}
      {:ok, channel, user, membership} ->
        if channel.owner_id == user.id do
          do_check_invit_limit channel, user, membership
        else
          {:forbidden, :not_admin}
        end
    end
  end

  defp do_check_invit_limit(channel, user, membership) do
    conf = Application.fetch_env! :epchat, :channels
    case Db.Tokens.count_for_channel channel.id do
      {:error, reason} -> {:error, reason}
      {:ok, nb} ->
        if nb >= conf.members_limit do
          {:forbidden, :tokens_limit}
        else
          case Db.Memberships.count_members channel.id do
            {:error, reason} -> {:error, reason}
            {:ok, nb} ->
              if nb >= conf.members_limit do
                {:forbidden, :members_limit}
              else
                do_adm_request_invit_link channel, user, membership
              end
          end
        end
    end
  end

  defp do_adm_request_invit_link(channel, _user, _membership) do
    # Generate a token for the channel
    case Db.Tokens.create channel.id do
      {:error, reason} -> {:error, reason}
      {:ok, nil} -> {:error, :token_not_created}
      {:ok, token} ->
        msg = %{token: token.id}
        {:ok, msg}
    end
  end

  # -----

  def adm_close(channel_id, user_id) do
    case get_channel_and_user channel_id, user_id, true do
      {:error, reason} -> {:error, reason}
      {:not_found, reason} -> {:not_found, reason}
      {:not_member, _, _} -> {:forbidden, :not_member}

      {:ok, channel, user, _membership} ->
        if channel.owner_id == user.id do
          Channels.Manager.close_channel channel.id, :adm_closed
          :ok
        else
          {:forbidden, :not_admin}
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
