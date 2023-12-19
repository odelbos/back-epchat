defmodule Epchat.Channels do
  require Logger
  alias Epchat.Db

  def join(channel_id, user_id, pid) do
    #
    # TODO: Need to broadcast the join to all other channel members
    #
    case get_channel_and_user channel_id, user_id, true do
      {:error, reason} -> {:error, reason}
      {:not_found, reason} -> {:not_found, reason}

      {:not_member, channel, user} ->
        case Db.Memberships.create channel, user, pid do
          {:error, reason} -> {:error, reason}
          {:ok, nil} -> {:error, :membership_not_created}
          {:ok, _membership} ->
            # TODO: -------------------------------Duplicate-Code------ REF-01
            msg = %{
              user: %{id: user.id, nickname: user.nickname},
            }
            {:ok, msg}
            # ------------------------------------------------------- / REF-01
        end

      {:ok, channel, user, _membership} ->
        case Db.Memberships.update_pid channel.id, user.id, pid do
          {:error, reason} -> {:error, reason}
          {:ok, nil} -> {:error, :membership_not_exists}
          {:ok, _membership} ->
            msg = %{
            # TODO: -------------------------------Duplicate-Code------ REF-01
              user: %{id: user.id, nickname: user.nickname},
            }
            {:ok, msg}
            # ------------------------------------------------------- / REF-01
        end
    end
  end

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
