defmodule Laphub.Laps.Importer do
  alias NimbleCSV.RFC4180, as: CSV
  alias Laphub.{Repo, Time}
  alias Laphub.Laps.{ActiveSesh, Sesh}

  @keys [
    "Speed (MPH)",
    "Latitude",
    "Longitude",
    "Lap"
  ]
  def from_trackaddict_csv(path, session) do
    {:ok, pid} = ActiveSesh.get_or_start(session)

    path
    |> File.stream!()
    |> Stream.reject(fn line ->
      String.starts_with?(line, "#")
    end)
    |> CSV.parse_stream(skip_headers: false)
    |> Stream.transform(nil, fn
      header, nil ->
        {[], header}

      row, header ->
        {[Enum.zip(header, row) |> Enum.into(%{})], header}
    end)
    |> Stream.map(fn row ->
      millis = trunc((Map.get(row, "UTC Time") |> String.to_float()) * 1_000)
      key = Time.utc_millis_to_key(millis)
      {key, Map.take(row, @keys)}
    end)
    |> Stream.chunk_every(20, 20, [])
    |> Enum.each(fn batch ->
      ActiveSesh.publish_all(pid, batch)
    end)
  end

  def run do
    sesh = Repo.get(Sesh, 3) |> IO.inspect()
    from_trackaddict_csv("/home/chris/Desktop/ORP2022/day2.csv", sesh)
  end

  alias Laphub.Laps.Timeseries

  def backfill() do
    sesh = Repo.get(Sesh, 3) |> IO.inspect()
    sesh = Sesh.clear(sesh) |> Repo.update!()

    {:ok, pid} = ActiveSesh.get_or_start(sesh)

    {:ok, db} = Timeseries.init(sesh.timeseries)

    Timeseries.all(db)
    |> Stream.map(fn {k, v} ->
      {to_string(trunc(String.to_integer(k) / 1000)), v}
    end)
    |> Stream.chunk_every(20, 20, [])
    |> Enum.each(fn batch ->
      ActiveSesh.publish_all(pid, batch)
    end)
  end

  # alias Laphub.Laps.Importer
end
