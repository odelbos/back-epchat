defmodule Epchat.ChannelHandler do
  alias Epchat.Channels

  def init(_args) do
    {:ok, %{user_id: nil, channels: []}}
  end

  # -----

  # Add the user_id to the state
  def handle_info({:user_id, user_id}, state) do
    {:ok, Map.put(state, :user_id, user_id)}
  end

  # -----

  def handle_in({"sk_ping", [opcode: :text]}, state) do
    {:reply, :ok, {:text, '{"event": "sk_pong"}'}, state}
  end

  # All messages must have the following format:
  # {
  #   "channel_id": ...,
  #   "event": ...,
  #   data: ...,
  # }
  # ... and must be JSON encoded.
  def handle_in({msg, [opcode: :text]}, state) do
    payload = Jason.decode! msg, keys: :atoms!
    %{channel_id: channel_id, event: event, data: data} = payload
    event channel_id, event, data, state
  end

  # -----

  def event(channel_id, "ch_join", _data, state) do
    case Channels.join channel_id, state.user_id, self() do
      {:ok, msg} ->
        new_state = Map.put(state, :channels, [channel_id | state.channels])

        # TODO: -----------------------------Duplicate-Code----- REF-020
        data = %{
          channel_id: channel_id,
          event: "ch_joined",
          data: msg,
        }
        # TODO: Hendle json encoding error
        {_, json} = Jason.encode_to_iodata data
        {:reply, :ok, {:text, json}, new_state}
        # ----------------------------------------------------- / REF-020

      {:error, _reason} ->
        # TODO: -----------------------------Duplicate-Code----- REF-020
        data = %{
          channel_id: channel_id,
          event: "ch_error",
          data: %{
            msg: "Cannot join the channel",
          },
        }
        # TODO: Hendle json encoding error
        {_, json} = Jason.encode_to_iodata data
        {:reply, :ok, {:text, json}, state}
        # ----------------------------------------------------- / REF-020
    end
  end

  def event(channel_id, "ch_members", _data, state) do
    case Channels.members channel_id, state.user_id do
      {:ok, msg} ->
        # TODO: -----------------------------Duplicate-Code----- REF-020
        data = %{
          channel_id: channel_id,
          event: "ch_members",
          data: msg,
        }
        # TODO: Hendle json encoding error
        {_, json} = Jason.encode_to_iodata data
        {:reply, :ok, {:text, json}, state}
        # ----------------------------------------------------- / REF-020

      {:error, _reason} ->
        # TODO: -----------------------------Duplicate-Code----- REF-020
        data = %{
          channel_id: channel_id,
          event: "ch_error",
          data: %{
            msg: "Cannot get the channel members",
          },
        }
        # TODO: Hendle json encoding error
        {_, json} = Jason.encode_to_iodata data
        {:reply, :ok, {:text, json}, state}
        # ----------------------------------------------------- / REF-020
    end
  end
end
