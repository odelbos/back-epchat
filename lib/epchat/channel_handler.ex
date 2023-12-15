defmodule Epchat.ChannelHandler do

  def init(_args) do
    {:ok, %{user_id: nil}}
  end

  # -----

  # Add the user_id to the state
  def handle_info({:user_id, user_id}, state) do
    {:ok, Map.put(state, :user_id, user_id)}
  end

  # -----

  def handle_in({"ping", [opcode: :text]}, state) do
    {:reply, :ok, {:text, "pong"}, state}
  end
end
