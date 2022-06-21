defmodule LaphubWeb.LapView do
  use LaphubWeb, :live_view

  def render(assigns) do
    ~H"""
      <div class="laps" id="LapViewer" phx-hook="LapViewer">hi</div>


    """
  end

  def mount(_params, %{}, socket) do
    :timer.send_interval(50, :foo)
    socket =
        socket
        |> assign(:data, [])
    {:ok, socket}
  end

  def handle_info(:foo, socket) do
    IO.inspect :foo

    now = DateTime.to_unix(DateTime.utc_now(), :millisecond)
    row = %{
      t: now,
      series: %{
        coolant_temp: 255 + :rand.normal() * 5,
        coolant_pres: 5 + :rand.normal() * 10,
        # oil_temp: 32 + :rand.normal() * 10,
        # oil_pres: 32 + :rand.normal() * 10,

      }
    }
    socket = push_event(socket, "foo", %{append: [row]})
    {:noreply, socket}
  end
end
