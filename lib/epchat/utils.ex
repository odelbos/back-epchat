defmodule Epchat.Utils do

  def generate_b62(length) do
    :crypto.strong_rand_bytes(length * 2)
    |> Base.encode64(padding: false)
    |> String.replace(["+", "/"], "")
    |> String.slice(0..length-1) 
  end
end
