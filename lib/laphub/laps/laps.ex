defmodule Laphub.Laps do
  import Ecto.Query
  alias Laphub.Repo
  alias Laphub.Laps.{Track, Sesh}

  def tracks() do
    Repo.all(from(t in Track))
  end

  def my_sessions(user_id) do
    Repo.all(
      from(
        s in Sesh,
        inner_join: t in assoc(s, :track),
        where: s.user_id == ^user_id,
        preload: [:track]
      )
    )
  end

  def my_sesh(user_id, id) do
    Repo.one(
      from(
        s in Sesh,
        inner_join: t in assoc(s, :track),
        where: s.user_id == ^user_id and s.id == ^id,
        preload: [:track]
      )
    )
  end

  defmodule ActiveSesh do
    use GenServer
    alias Phoenix.PubSub
    alias Laphub.Laps.Timeseries

    def create() do
      :ets.new(__MODULE__, [:named_table, :public])
    end

    def all() do
      :ets.tab2list(__MODULE__)
    end

    def get_or_start(sesh) do
      case :ets.lookup(__MODULE__, sesh.id) do
        [{_, pid}] ->
          {:ok, pid}

        [] ->
          {:ok, pid} = start(sesh)
          :ets.insert(__MODULE__, {sesh.id, pid})

          spawn(fn ->
            ref = Process.monitor(pid)

            receive do
              {:DOWN, ^ref, _, _, _reason} ->
                :ets.delete(__MODULE__, sesh.id)
            end
          end)

          {:ok, pid}
      end
    end

    defp topic(sesh), do: "session:#{sesh.id}"

    defp start(sesh) do
      GenServer.start(__MODULE__, [sesh])
    end

    defmodule State do
      defstruct [:sesh, :ts, :columns, :range]
    end

    def init([sesh]) do
      {:ok, ts} = Timeseries.init(sesh.timeseries)

      {columns, range} = playback_existing(sesh, ts)

      state = %State{
        sesh: sesh,
        ts: ts,
        columns: columns,
        range: range
      }

      {:ok, state}
    end

    def handle_cast({:event, key, row}, %State{sesh: sesh, ts: ts} = state) do
      :ok = Timeseries.put(ts, key, row)

      new_state = %State{
        state
        | columns: update_columns(state.columns, row),
          range: update_range(state.range, key)
      }

      if new_state != state do
        PubSub.broadcast(
          Laphub.InternalPubSub,
          topic(sesh),
          {__MODULE__, {:change, new_state.columns, new_state.range}}
        )
      end

      PubSub.broadcast(
        Laphub.InternalPubSub,
        topic(sesh),
        {__MODULE__, {:append, key, row}}
      )

      {:noreply, new_state}
    end

    def handle_call({:stream, fun}, _, %State{ts: ts} = state) do
      stream = fun.(ts)
      {:reply, stream, state}
    end

    def handle_call(:columns, _, %State{columns: columns} = state) do
      {:reply, columns, state}
    end

    def handle_call(:range, _, %State{range: range} = state) do
      {:reply, range, state}
    end

    defp now() do
      :erlang.system_time(:microsecond) |> to_string
    end

    def datetime_to_key(dt) do
      {:ok, dt} = DateTime.from_naive(dt, "Etc/UTC")

      dt
      |> DateTime.to_unix(:microsecond)
      |> to_string
    end

    def key_to_datetime(key) do
      {:ok, dt} = DateTime.from_unix(String.to_integer(key), :microsecond)
      dt
    end

    def subtract(key, seconds) do
      {i, ""} = Integer.parse(key)
      to_string(i - seconds * 1000 * 1000)
    end

    defp update_columns(existing, row) do
      MapSet.union(existing, MapSet.new(Map.keys(row)))
    end

    def update_range({lo, hi}, timestamp) do
      {min(lo, timestamp), max(hi, timestamp)}
    end

    defp playback_existing(sesh, ts) do
      # I guess this is kind of wrong if the pg clock and
      # our clock drift...
      ia = datetime_to_key(sesh.inserted_at)
      initial_range = {ia, ia}
      # It is sorted
      Enum.reduce(Timeseries.all(ts), {MapSet.new(), initial_range}, fn {timestamp, row},
                                                                        {columns, range} ->
        columns = update_columns(columns, row)

        range =
          case range do
            {nil, nil} -> {timestamp, timestamp}
            {lo, _hi} -> {lo, timestamp}
          end

        {columns, range}
      end)
    end

    def publish(pid, %{"label" => label, "value" => value}) do
      key = now()
      row = Map.put(%{}, label, value)
      GenServer.cast(pid, {:event, key, row})
    end

    def subscribe(sesh) do
      PubSub.subscribe(Laphub.InternalPubSub, topic(sesh))
    end

    def columns(pid) do
      GenServer.call(pid, :columns)
    end

    def range(pid) do
      GenServer.call(pid, :range)
    end

    def stream(pid, fun) do
      GenServer.call(pid, {:stream, fun})
    end
  end
end
