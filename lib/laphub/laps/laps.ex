defmodule Laphub.Laps do
  import Ecto.Query
  alias Laphub.{Time, Repo}
  alias Laphub.Laps.{Track, Sesh}
  require Logger

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

    defmodule State do
      defstruct [:sesh, :range, all_series: %{}]
    end

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

          Logger.info("#{sesh.id} started at #{inspect(pid)}")
          {:ok, pid}
      end
    end

    defp topic(sesh), do: "session:#{sesh.id}"

    defp start(sesh) do
      GenServer.start(__MODULE__, [sesh])
    end

    def init([sesh]) do
      all =
        Enum.reduce(sesh.series, %{}, fn series, acc ->
          {_, acc} = add_series(series, acc)
          acc
        end)

      range = {from_k, to_k} = playback_existing_range(sesh, all)

      from_range = Time.key_to_datetime(from_k)
      to_range = Time.key_to_datetime(to_k)
      Logger.info("Started sesh #{sesh.id} with range #{from_range}:#{to_range}")

      state = %State{
        sesh: sesh,
        all_series: all,
        range: range
      }

      {:ok, state}
    end

    def merge_range({l1, h1}, {l2, h2}) do
      {min(l1, l2), max(h1, h2)}
    end

    def update_range({l1, h1}, new_key) do
      {min(l1, new_key), max(h1, new_key)}
    end

    defp playback_existing_range(sesh, all_series) do
      # I guess this is kind of wrong if the pg clock and
      # our clock drift...
      ia = Time.to_key(sesh.inserted_at)
      initial_range = {ia, ia}
      # It is sorted
      Enum.reduce(all_series, initial_range, fn {_col, ts}, range ->
        merge_range(Timeseries.range(ts), range)
      end)
    end

    defp add_series(series, all_series) do
      Logger.info("Adding series: #{series.name}")
      {:ok, ts} = Timeseries.init(series.path)
      {ts, Map.put(all_series, series.name, ts)}
    end

    defp put_entry(%State{sesh: sesh, all_series: all_series} = state, column, key, value) do
      {ts, state} =
        case Map.get(all_series, column) do
          nil ->
            new_sesh = Repo.update!(Sesh.add_series(sesh, column))
            new_series = Enum.find(new_sesh.series, fn s -> s.name == column end)
            {ts, new_all} = add_series(new_series, all_series)
            Logger.info("Created new series for #{sesh.id} #{column}")
            # PubSub.broadcast(
            #   Laphub.InternalPubSub,
            #   topic(sesh),
            #   {__MODULE__, {:change, new_state.columns, new_state.range}}
            # )

            {ts, %State{state | sesh: new_sesh, all_series: new_all}}

          ts ->
            {ts, state}
        end

      :ok = Timeseries.put(ts, key, value)

      state
    end

    def handle_cast({:event, events}, %State{sesh: sesh} = state) do
      new_state =
        Enum.reduce(events, state, fn {key, row}, state ->
          state =
            Enum.reduce(row, state, fn {column, value}, state ->
              put_entry(state, column, key, value)
            end)

          %State{state | range: update_range(state.range, key)}
        end)

      # TODO: batch optimize
      Enum.each(events, fn {key, row} ->
        PubSub.broadcast(
          Laphub.InternalPubSub,
          topic(sesh),
          {__MODULE__, {:append, key, row}}
        )
      end)

      {:noreply, new_state}
    end

    def handle_call({:stream, which, fun}, _, %State{} = state) do
      {:reply, fun.(Map.get(state.all_series, which)), state}
    end

    def handle_call(:columns, _, %State{all_series: all} = state) do
      {:reply, Map.keys(all), state}
    end

    def handle_call(:range, _, %State{range: range} = state) do
      {:reply, range, state}
    end

    def publish(pid, %{"label" => label, "value" => value}) do
      key = Time.now()
      row = Map.put(%{}, label, value)
      Logger.info("pub #{label} #{inspect(value)}")
      GenServer.cast(pid, {:event, [{key, row}]})
    end

    def publish_all(pid, rows) do
      GenServer.cast(pid, {:event, rows})
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

    def stream(pid, which, fun) do
      GenServer.call(pid, {:stream, which, fun})
    end

    def db(pid, which) do
      stream(pid, which, fn db -> db end)
    end
  end
end
