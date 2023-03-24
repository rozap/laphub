defmodule Laphub.Laps.TimeseriesQueries do
  alias Laphub.Laps.{ActiveSesh, Timeseries}
  alias Laphub.Time

  defp int_range({lo, hi}) do
    {String.to_integer(lo), String.to_integer(hi)}
  end

  def laps(sesh_pid, from_lap, to_lap) do
    case ActiveSesh.db(sesh_pid, "lap") do
      nil ->
        []

      db ->
        range = Timeseries.range(db) |> int_range

        {from_key, _to_key} =
          binsearch(db, range, fn {_k, v} ->
            case String.to_integer(v) do
              l when l > from_lap -> :gt
              l when l < from_lap -> :lt
              l when l == from_lap -> :eq
            end
          end)

        db
        |> Timeseries.walk_forward(to_string(from_key))
        |> Stream.map(fn {k, lap} -> {k, String.to_integer(lap)} end)
        |> Stream.filter(fn {k, lap} -> lap >= from_lap end)
        |> Stream.take_while(fn {k, lap} -> lap <= to_lap end)
        |> state_changes
        |> Stream.transform(nil, fn
          {k, lapno}, nil ->
            {[], Time.key_to_millis(k)}

          {k, lapno}, last_k ->
            this_k = Time.key_to_millis(k)
            delta = Time.millis_to_time(this_k - last_k)
            label = Time.time_to_label(delta)
            row = %{lapno: lapno, time: delta, label: label}
            {[{k, row}], this_k}
        end)
    end
  end

  defp state_changes(stream) do
    Stream.transform(stream, nil, fn
      {_, value} = row, nil ->
        {[row], value}

      {_, value} = row, value ->
        {[], value}

      {_, value} = row, b ->
        {[row], value}
    end)
  end

  defp binsearch(db, {from_key, to_key} = range, comparator) do
    middle = from_key + trunc((to_key - from_key) / 2)
    case Timeseries.walk_forward(db, to_string(middle)) |> Enum.take(1) do
      [row] ->
        case comparator.(row) do
          :gt ->
            IO.puts("Search lo")
            binsearch(db, {from_key, middle}, comparator)
          :lt ->
            IO.puts("Search hi")
            binsearch(db, {middle, to_key}, comparator)
          :eq -> range
        end
      [] ->
        range
    end
  end
end
