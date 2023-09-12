defmodule Laphub.Laps.ActiveSesh do
  use GenServer
  alias Phoenix.PubSub
  alias Laphub.Laps.Timeseries
  alias Laphub.Laps.Sesh
  alias Laphub.Repo
  alias Laphub.Time
  require Logger
  alias Laphub.Laps.Reducers.GpsToLap

  defmodule State do
    defstruct [:sesh, :range, column_states: %{}, timeseries: %{}]
  end

  defmodule ColumnState do
    defstruct [:reducer, :reducer_state]
  end

  def create() do
    :ets.new(__MODULE__, [:named_table, :public])
  end

  def all() do
    :ets.tab2list(__MODULE__)
  end

  def get_or_start(sesh_id) when is_integer(sesh_id) do
    Repo.get(Sesh, sesh_id) |> get_or_start()
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
    sesh = Repo.preload(sesh, :track)

    state = %State{
      sesh: sesh,
      column_states: %{},
      timeseries: %{},
      range: {0, 0}
    }

    state =
      Enum.reduce(sesh.series, state, fn column, state ->
        {_ts, state} = get_or_create_timeseries(column, state)
        state
      end)

    range = {from_k, to_k} = playback_existing_range(sesh, state)

    from_range = Time.key_to_datetime(from_k)
    to_range = Time.key_to_datetime(to_k)
    Logger.info("Started sesh #{sesh.id} with range #{from_range}:#{to_range}")

    state = %State{
      state
      | range: range
    }

    {:ok, state}
  end

  # defmodule SeshReducer do
  #   @behaviour
  #   def init()
  #   def reduce(key, value) :: []
  # end

  defmodule IdentityReducer do
    def init(_sesh), do: :nostate
    def reduce(key, column, value, :nostate), do: {[{key, column, value}], :nostate}
  end

  defp reducers() do
    %{
      "gps" => GpsToLap
    }
  end

  def merge_range({l1, h1}, {l2, h2}) do
    {min(l1, l2), max(h1, h2)}
  end

  def update_range({l1, h1}, new_key) do
    {min(l1, new_key), max(h1, new_key)}
  end

  defp playback_existing_range(sesh, state) do
    # I guess this is kind of wrong if the pg clock and
    # our clock drift...
    ia = Time.to_key(sesh.inserted_at)
    initial_range = {ia, ia}
    # It is sorted
    Enum.reduce(state.timeseries, initial_range, fn {_col, ts}, range ->
      merge_range(Timeseries.range(ts), range)
    end)
  end

  # Flat map the events through some behavior
  #
  #   Ex: GPS events get added to the GPS timeseries,
  #       but may emit an entry into the Laps timeseries
  #       when the GPS goes through the start/finish
  #
  #   it's not really an Annotation, but lets call it that
  #   AnnotationBehaviour has a state as part of the reduction
  #   and it's passed the {event, its_state} and returns a list
  #   of events to emit into its column and its new state

  #

  # needed for writes
  defp get_or_create_column_state(column, state) do
    case Map.get(state.column_states, column) do
      nil ->
        reducer = Map.get(reducers(), column, IdentityReducer)
        rs = reducer.init(state.sesh)

        cs = %ColumnState{
          reducer: reducer,
          reducer_state: rs
        }

        {cs, %State{state | column_states: Map.put(state.column_states, column, cs)}}

      cs ->
        {cs, state}
    end
  end

  # needed for reads
  defp get_or_create_timeseries(column, state) do
    case Map.get(state.timeseries, column) do
      nil ->
        new_sesh = Repo.update!(Sesh.add_series(state.sesh, column))
        new_series = Enum.find(new_sesh.series, fn s -> s.name == column end)
        Logger.info("Adding series: #{column}")
        {:ok, ts} = Timeseries.init(new_series.path)
        # PubSub.broadcast(
        #   Laphub.InternalPubSub,
        #   topic(sesh),
        #   {__MODULE__, {:change, new_state.columns, new_state.range}}
        # )
        new_state = %State{
          state
          | sesh: new_sesh,
            timeseries: Map.put(state.timeseries, column, ts)
        }

        {ts, new_state}

      ts ->
        {ts, state}
    end
  end

  def handle_cast({:event, events}, %State{sesh: sesh} = state) do
    {events, state} =
      Enum.reduce(events, {[], state}, fn {key, row}, {events, state} ->
        Enum.reduce(row, {events, state}, fn {column, value}, {events, state} ->
          {cs, state} = get_or_create_column_state(column, state)
          {more_events, rs} = cs.reducer.reduce(key, column, value, cs.reducer_state)

          new_cs = %ColumnState{cs | reducer_state: rs}

          {events ++ more_events,
           %State{
             state
             | column_states: Map.put(state.column_states, column, new_cs)
           }}
        end)
      end)

    new_state =
      Enum.reduce(events, state, fn {key, column, value}, state ->
        {ts, state} = get_or_create_timeseries(column, state)
        :ok = Timeseries.put(ts, key, value)

        %State{state | range: update_range(state.range, key)}
      end)

    # TODO: batch optimize
    Enum.group_by(events, fn {key, _column, _value} -> key end)
    |> Enum.map(fn {key, events} ->
      row =
        events
        |> Enum.map(fn {_key, column, row} -> {column, row} end)
        |> Enum.into(%{})

      PubSub.broadcast(
        Laphub.InternalPubSub,
        topic(sesh),
        {__MODULE__, {:append, key, row}}
      )
    end)

    {:noreply, new_state}
  end

  def handle_call({:stream, which, fun}, _, %State{} = state) do
    {:reply, fun.(Map.get(state.timeseries, which)), state}
  end

  def handle_call(:columns, _, %State{timeseries: all} = state) do
    {:reply, Map.keys(all), state}
  end

  def handle_call(:range, _, %State{range: range} = state) do
    {:reply, range, state}
  end

  def publish(pid, label, value) do
    key = Time.now()
    row = Map.put(%{}, label, value)
    GenServer.cast(pid, {:event, [{to_string(key), row}]})
  end

  def publish_all(pid, label, rows) do
    key = Time.now()

    rows =
      Enum.map(rows, fn {cell_offset, value} ->
        {to_string(key + cell_offset), Map.put(%{}, label, value)}
      end)

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
