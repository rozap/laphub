defmodule LaphubWeb.Components.DriversComponent do
  use LaphubWeb.Components.Widget
  alias Laphub.Laps.{Timeseries, ActiveSesh}
  import LaphubWeb.Components.Util
  alias Laphub.Time

  def init(socket) do
    socket =
      socket
      |> assign(:drivers, Enum.map(
        socket.assigns.sesh.team.teammates_users, fn u ->
          u.name
        end))
      |> assign(:current_driver, nil)
      |> set_current()

    {:ok, socket}
  end

  def set_current(socket) do
    current = ActiveSesh.stream(socket.assigns.pid, "drivers", fn
      nil -> nil
      db ->
        Timeseries.all_reversed(db)
        |> Enum.take(1)
        |> case do
          [{_k, driver}] -> driver
          _ -> nil
        end
    end)

    assign(socket, :current_driver, current)
  end

  def handle_event("switch", %{"driver" => driver}, socket) do
    ActiveSesh.publish(socket.assigns.pid, "drivers", driver)
    {:noreply, assign(socket, :current_driver, driver)}
  end

  def render(assigns) do
    ~H"""
    <div class="drivers-component">
      <div class="button-group">
        <%= for driver <- @drivers do %>
          <button role="button"
            class={classnames([{"outline", driver != @current_driver}])}
            phx-click="switch"
            phx-value-driver={driver}>
            <%= driver %>
          </button>
        <% end %>
      </div>
    </div>
    """
  end
end
