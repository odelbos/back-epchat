defmodule Epchat.Channels.Handler do
  alias Epchat.Channels

  def init(_args) do
    {:ok, %{user_id: nil, channels: []}}
  end

  # -----

  # Add the user_id to the state
  def handle_info({:user_id, user_id}, state) do
    {:ok, Map.put(state, :user_id, user_id)}
  end

  # Remove closed channel from the state
  # NOTE: Closing a channel does not mean closing the websocket
  def handle_info({:channel_closed, channel_id}, state) do
    channels = Enum.filter(state.channels, fn c -> c != channel_id end)
    {:ok, Map.put(state, :channels, channels)}
  end
  
  # Push a msg from server to client
  def handle_info({:push, _opcode, msg}, state) do
    {:reply, :ok, {:text, msg}, state}
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
        reply channel_id, :ch_joined, msg, new_state

      error -> reply_error channel_id, error, state
    end
  end

  def event(channel_id, "ch_members", _data, state) do
    case Channels.members channel_id, state.user_id do
      {:ok, msg} ->
        reply channel_id, :ch_members, msg, state

      error -> reply_error channel_id, error, state
    end
  end

  def event(channel_id, "ch_msg", %{msg: msg} = _data, state) do
    case Channels.message channel_id, state.user_id, msg do
      :ok -> {:ok, state}
      error -> reply_error channel_id, error, state
    end
  end

  # -----

  # Websocket crashed or closed by client
  # (need to leave all channels)
  def terminate(code, state) do
    # NOTE: code can be: :timeout, :remote

    IO.puts "--- Terminate --------"       # TODO: Debug code
    IO.inspect code
    IO.inspect state
    IO.puts "----------------------"

    # Leave all joinned channels
    for channel_id <- state.channels do
      Channels.leave channel_id, state.user_id
    end
    {:ok, state}
  end

  # -----

  defp reply(channel_id, event, msg, state) do
    data = %{
      channel_id: channel_id,
      event: event,
      data: msg,
    }
    # TODO: Hendle json encoding error
    {_, json} = Jason.encode_to_iodata data
    {:reply, :ok, {:text, json}, state}
  end

  defp reply_error(channel_id, error, state) do
    msg = case error do
      {:error, _reason} ->
        %{code: 500, msg: "Internal Server Error"}

      {:not_member, :not_member} ->
        %{code: 400, tag: :not_member, msg: "Not a channel member"}

      {:not_found, :channel_and_user} ->
        %{code: 400, tag: :channel_and_user, msg: "Channel and user does not exists"}

      {:not_found, :channel} ->
        %{code: 400, tag: :channel, msg: "Channel does not exists"}

      {:not_found, :user} ->
        %{code: 400, tag: :user, msg: "User does not exists"}
    end

    reply channel_id, :ch_error, msg, state
  end
end