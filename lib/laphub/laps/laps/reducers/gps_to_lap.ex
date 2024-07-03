defmodule Laphub.Laps.Reducers.GpsToLap do
  require Logger
  alias Laphub.Time
  alias Laphub.Laps.Sesh
  alias Laphub.Laps.Timeseries

  defmodule State do
    defstruct [:sesh, :previous_coords, :lapnum, :previous_time]
  end

  def init(%Sesh{} = sesh, timeseries) do
    lapnum = case Map.get(timeseries, "lap") do
      nil -> 0
      db ->
        Timeseries.all_reversed(db)
        |> Enum.take(1)
        |> case do
          [{_, lapno}] -> lapno
          _ -> 0
        end
    end

    %State{sesh: sesh, previous_coords: nil, previous_time: nil, lapnum: lapnum}
  end

  defp has_crossed?(coord, %{previous_coords: prev_coord, sesh: sesh}) do
    with {y0, x0} <- prev_coord,
         {y1, x1} <- coord,
         [%{"lat" => ly0, "lng" => lx0}, %{"lat" => ly1, "lng" => lx1}] <-
           sesh.track.start_finish_line do
      {intersect, _, _} = SegSeg.intersection({x0, y0}, {x1, y1}, {lx0, ly0}, {lx1, ly1})
      intersect
    else
      _ -> false
    end
  end

  defp emit_lap(key, current_coords, %State{previous_coords: nil, previous_time: nil} = state) do
    {[], %State{state | previous_coords: current_coords, previous_time: Time.key_to_millis(key)}}
  end

  defp emit_lap(key, current_coords, state) do
    if has_crossed?(current_coords, state) do
      time = Time.key_to_millis(key)

      lapnum = state.lapnum
      new_state = %State{state | previous_time: time, lapnum: lapnum + 1}
      {[{key, "lap", lapnum}], new_state}
    else
      {[], state}
    end
  end

  def reduce(key, column, [lat, lng], state) do
    with {lat, ""} <- Float.parse(lat),
         {lng, ""} <- Float.parse(lng) do
      {lap_events, new_state} = emit_lap(key, {lat, lng}, state)
      new_state = %State{new_state | previous_coords: {lat, lng}}
      {[{key, column, %{lat: lat, lng: lng}}] ++ lap_events, new_state}
    else
      e ->
        Logger.warning("Dropping Gps sample, cannot parse: #{inspect e} #{inspect {lat, lng}}")
        {[], state}
    end
  end
end
