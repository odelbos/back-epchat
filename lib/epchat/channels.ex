defmodule Epchat.Channels do
  require Logger
  alias Epchat.Db

  def join(channel_id, user_id, pid) do

    # TODO: Manage possible errors when getting channel and user
    {:ok, channel} = Db.Channels.get channel_id
    {:ok, user} = Db.Users.get user_id

    case Db.Memberships.get channel.id, user.id do
      {:error, reason} -> {:error, reason}

      {:ok, nil} ->
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

      {:ok, _membership} ->
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
end
