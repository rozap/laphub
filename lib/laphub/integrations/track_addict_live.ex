defmodule Laphub.Integrations.TrackAddictLive do
  use GenServer
  require Logger
  alias Laphub.Integrations.Telemetry.Position
  alias Laphub.Laps.ActiveSesh

  def start_link(client_id, sesh), do: GenServer.start_link(__MODULE__, [client_id, sesh])

  def init([client_id, sesh]) do
    :timer.send_interval(500, :poll)
    {:ok, {client_id, sesh}}
  end

  defp poke_invalid_json(body) do
    Regex.replace(~r/0x[A-F0-9]{6}/, body, "false")
  end

  def handle_info(:poll, {client_id, sesh} = state) do
    rand = trunc(:rand.uniform() * 10_000_000)

    res =
      Finch.build(
        :get,
        "https://live.racerender.com/ViewData.php?ID=#{client_id}&MapLap=0&ListLap=999999&GetDescInfo=0&Rand=#{rand}"
      )
      |> Finch.request(Laphub.Http.TrackAddict)

    with {:ok, %Finch.Response{status: 200, body: body}} <- res,
         body <- poke_invalid_json(body),
         {:ok, body} <- Jason.decode(body),
         %{
           "BestLap" => best_lap,
           "BestLapTime" => best_lap_time,
           "CurLap" => current_lap,
           "Heading" => heading,
           "LapAccuracy" => accuracy,
           "Map" => map,
           "Speed" => speed,
           "Status" => status,
           "TopSpeed" => top_speed,
           "User" => [
             %{
               "Lat" => lat,
               "Lon" => lon
             }
           ],
           "UserOnline" => online
         } <- body do
      posn = %Position{
        best_lap: best_lap,
        best_lap_time: best_lap_time,
        current_lap: current_lap,
        heading: heading,
        accuracy: accuracy,
        map: map,
        speed: speed,
        status: status,
        top_speed: top_speed,
        lat: lat,
        lon: lon,
        online: online == 1
      }

      ActiveSesh.publish(sesh, %{position: posn})
    else
      oof ->
        Logger.warn("Failed to get trackaddit feed: #{inspect(oof)}")
    end

    {:noreply, state}
  end
end
