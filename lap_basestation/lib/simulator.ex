defmodule LapBasestation.Simulator do
  @dimension_lookup Enum.map(LapBasestation.Handler.dimensions(), fn {prefix, name, unit, _evname} ->
    {name, prefix}
  end) |> Enum.into(%{})

  defp send_temps_etc(pid) do
    simulated = [
      :oil_pres,
      :coolant_pres,
      :oil_temp,
      :coolant_temp,
      :voltage,
      :rpm
    ]

    Enum.each(simulated, fn dimension ->
      value = :rand.uniform() * 100
      send_packet(pid, dimension, value)
    end)

    :timer.sleep(500)
    send_temps_etc(pid)
  end

  defp send_packet(pid, dimension, value) do
    prefix = Map.get(@dimension_lookup, dimension)
    send(pid, {:circuits_uart, nil, "#{prefix}:#{value}"})
  end

  def into_gps_frames(csv_loc) do
    File.stream!(csv_loc)
    |> NimbleCSV.RFC4180.parse_stream()
    |> Stream.filter(fn
      ["#" <> _ | _] -> false
      _ -> true
    end)
    |> Stream.transform(nil, fn
      header, nil -> {[], header}
      row, header -> {[Enum.zip(header, row) |> Enum.into(%{})], header}
    end)
    |> Stream.map(fn row ->
      %{"Time" => t, "Speed (MPH)" => s, "Latitude" => lat, "Longitude" => lng} = row
      {t, ""} = Float.parse(t)
      %{time: t, speed: s, lat: lat, lng: lng}
    end)
    |> Stream.chunk_by(fn %{time: t} -> trunc(t) end)
    |> Stream.flat_map(fn chunk ->
      gps_frame = Enum.map(chunk, fn %{time: t, lat: lat, lng: lng} ->
        offset_millis = trunc((t - trunc(t)) * 1000)
        "#{offset_millis}:#{lat},#{lng}"
      end)
      |> Enum.join("|")

      speed_frame = Enum.map(chunk, fn %{time: t, speed: speed} ->
        offset_millis = trunc((t - trunc(t)) * 1000)
        Enum.join([offset_millis, speed], ":")
      end)
      |> Enum.join("|")

      [{:gps, gps_frame}, {:speed, speed_frame}]
    end)
  end

  def send_gps(gps_loc, pid) do
    gps_loc
    |> into_gps_frames()
    |> Enum.each(fn {dimension, frame} ->
      send_packet(pid, dimension, frame)
      :timer.sleep(500)
    end)
  end


  def simulate(id, gps_loc \\ "../test/fixtures/theridge.csv") do
    {:ok, pid} = LapBasestation.up(id)

    spawn_link(fn ->
      send_temps_etc(pid)
    end)
    spawn_link(fn ->
      send_gps(gps_loc, pid)
    end)
  end
end
