defmodule Laphub.Laps.Reducers.GpsToLap do
  require Logger
  alias Laphub.Time
  alias Laphub.Laps.Sesh

  defmodule State do
    defstruct [:sesh, :previous_coords, :lapnum, :previous_time]
  end

  def init(%Sesh{} = sesh) do
    %State{sesh: sesh, previous_coords: nil, previous_time: nil, lapnum: 0}
  end

  defp has_crossed?(coord, %{previous_coords: prev_coord, sesh: sesh}) do

    # {y0, x0} = prev_coord
    # {y1, x1} = coord

    # [{ly0, lx0}, {ly1, lx1}] = sesh.track.start_finish_line

    # x0 < lx0 && x1 > lx0 && x0 < lx1 &&
    false
  end

  defp emit_lap(key, current_coords, %State{previous_coords: nil, previous_time: nil} = state) do
    {[], %State{state | previous_coords: current_coords, previous_time: Time.key_to_millis(key)}}
  end

  defp emit_lap(key, current_coords, state) do
    if has_crossed?(current_coords, state) do
      time = Time.key_to_millis(key)

      lapnum = state.lapnum
      new_state = %State{state | previous_time: time, lapnum: lapnum + 1}
      {[{key, "lap", %{lapnum: lapnum, time: time}}], new_state}
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
      _ ->
        Logger.warn("Dropping Gps sample, cannot parse")
        {[], state}
    end
  end
end
