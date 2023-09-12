defmodule Laphub.Integrations.TrackAddictCSV do


  def read(csv_loc) do
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


      %{time: t, speed: s, lat: lat, lng: lng}
    end)
  end
end
