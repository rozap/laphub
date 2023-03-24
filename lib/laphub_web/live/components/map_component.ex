defmodule LaphubWeb.Components.MapComponent do
  use Phoenix.LiveComponent
  import LaphubWeb.Components.Util
  alias Laphub.Laps.{ActiveSesh}
  alias Laphub.Laps.Timeseries

  def mount(socket) do
    {:ok, socket}
  end


  def update(assigns, socket) do
    parent = self()
    # this was the backfill test
    # spawn_link(fn ->
    #   case {
    #     ActiveSesh.db(assigns.pid, "Latitude"),
    #     ActiveSesh.db(assigns.pid, "Longitude")
    #   } do
    #     {nil, nil} -> :ok
    #     {lat_db, lng_db} ->
    #       lats = lat_db |> Timeseries.all
    #       lngs = lng_db |> Timeseries.all


    #       Stream.zip(lats, lngs)
    #       |> Stream.drop(50000)
    #       |> Enum.reduce(nil, fn
    #         {{k, _}, _}, nil -> String.to_integer(k)
    #         {{k, lat}, {_, lng}}, last ->
    #           send(parent, {:push_event, "position", %{lat: lat, lng: lng}})
    #           k = String.to_integer(k)
    #           :timer.sleep(k - last)
    #           k
    #       end)

    #   end


    # end)

    {:ok, assign(socket, assigns)}
  end



  def render(assigns) do
    ~H"""
    <div phx-hook="Map" class="map" id="map">


    </div>
    """
  end
end
