defmodule LaphubWeb.Components.MapComponent do
  use LaphubWeb.Components.Widget
  alias Laphub.Laps.{ActiveSesh}
  alias Laphub.Laps.{Track, Timeseries}

  def init_reply(_socket, widget) do
    track = %Track{
      coords: [
        %{"lat" => 47.2538, "lon" => -123.1957}
      ],
      title: "The Ridge Motorsports Park"
    }

    %{
      track: track,
      widget: widget
    }
  end

  def render(assigns) do
    ~H"""
    <div phx-hook="Map" class="map" phx-update="ignore" id={@widget.id}>


    </div>
    """
  end
end
