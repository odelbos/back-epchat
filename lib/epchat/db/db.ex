defmodule Epchat.Db.Db do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :db)
  end

  def init(args) do
    file = args.file
    {:ok, conn} = Exqlite.Basic.open file
    Epchat.Db.Schema.init conn
    {:ok, %{conn: conn, file: file}}
  end

  # -----

  def query(conn, query, params \\ []) do
    case Exqlite.Basic.exec conn, query, params do
      {:ok, _, _, _} = result ->
        Exqlite.Basic.rows result
      {:error, error, _} ->
        {:error, error.message}
    end
  end

  def execute(query, params \\ []) do
    GenServer.call :db, {:execute, query, params}
  end

  # -----

  def handle_call({:execute, query, params}, _from, %{conn: conn} = state) do
    rows = query(conn, query, params)
    {:reply, rows, state}
  end
end
