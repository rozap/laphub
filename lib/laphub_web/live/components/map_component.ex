defmodule LaphubWeb.Components.MapComponent do
  use LaphubWeb.Components.Widget
  alias Laphub.Laps.{ActiveSesh}
  alias Laphub.Laps.{Track, Timeseries}

  def init(socket) do
    track = %Track{
      coords: [
        %{"lat" => 47.2538, "lon" => -123.1957}
      ],
      title: "The Ridge Motorsports Park"
    }

    socket =
      push_event(socket, "map:init", %{
        track: track
      })

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div phx-hook="Map" class="map" phx-update="ignore" id="map">


    </div>
    """
  end
end
