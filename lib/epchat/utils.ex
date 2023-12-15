defmodule Epchat.Utils do

  def generate_b62(length) do
    :crypto.strong_rand_bytes(length * 2)
    |> Base.encode64(padding: false)
    |> String.replace(["+", "/"], "")
    |> String.slice(0..length-1) 
  end

  def pid_to_string(pid) do
    pid
    |> :erlang.pid_to_list()
    |> List.delete_at(0) |> List.delete_at(-1) |> to_string()
  end

  # Stolen from Elixir source code : lib/iex/lib/iex/helpers.ex
  def string_to_pid(str) do
    :erlang.list_to_pid ~c"<#{str}>"
  end
end
