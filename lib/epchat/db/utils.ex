defmodule Epchat.Db.Utils do

  # NOTE:
  # Exqlite result return a list of rows, and a list of fields names, like this:
  #
  # rows = [ ["IOaae7", "Joe"], ["snVn3k", "Jane"] ]
  # fields = ["id", "nickname"]
  #
  # The following 'reshape' functions are helpers to transform the result in:
  #
  # [ %{id: "IOaae7", nickname: "Joe"}, %{id: "snVn3k", nickname: "Jane"} ]

  def reshape_as_list_of_map(rows, fields) do
    Enum.reverse do_reshape_as_list_of_map(rows, fields, [])
  end

  defp do_reshape_as_list_of_map([], _fields, acc) do
    acc
  end

  defp do_reshape_as_list_of_map([row | rest], fields, acc) do
    new_row = reshape_row_as_map row, fields
    do_reshape_as_list_of_map rest, fields, [new_row | acc]
  end

  # -----

  def reshape_row_as_map(row, fields) do
    do_reshape_row_as_map(row, fields, %{})
  end

  defp do_reshape_row_as_map([], [], acc) do
    acc
  end

  defp do_reshape_row_as_map([value | row_rest], [name | fields_rest], acc) do
    do_reshape_row_as_map row_rest, fields_rest, Map.put(acc, String.to_atom(name), value)
  end
end
