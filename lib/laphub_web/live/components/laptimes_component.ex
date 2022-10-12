defmodule LaphubWeb.Components.LaptimesComponent do
  use Phoenix.LiveComponent
  import LaphubWeb.Components.Util
  alias LaphubWeb.Icons
  alias Laphub.Laps.TimeseriesQueries
  alias Laphub.Time

  def mount(socket) do
    {:ok, assign(socket, :page, 0)}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, fetch(socket)}
  end

  defp fetch(socket) do
    page_size = 10
    start_lap = socket.assigns.page * page_size
    end_lap = start_lap + 10

    ts = :erlang.system_time(:millisecond)
    laps =
      TimeseriesQueries.laps(socket.assigns.pid, start_lap, end_lap)
      |> Enum.into([])

    te = :erlang.system_time(:millisecond)
    assign(socket, :laps, laps)
  end

  def handle_event("prev", _, socket) do
    page = max(0, socket.assigns.page - 1)
    {:noreply, fetch(assign(socket, :page, page))}
  end
  def handle_event("next", _, socket) do
    page = socket.assigns.page + 1
    {:noreply, fetch(assign(socket, :page, page))}
  end

  defp get_column_name(:lapno), do: "Lap Number"
  defp get_column_name(:label), do: "Time"

  def render(assigns = %{laps: []}) do
    ~H"""
    <div class="lap-times">
      No lap times yet
    </div>
    """
  end


  def render(assigns) do
    laptime_columns = [:lapno, :label]

    ~H"""
    <div class="lap-times">
      <table>
        <thead>
          <tr>
            <%= for c <- laptime_columns do %>
              <th>
                <%= get_column_name(c) %>
              </th>
            <% end %>
          </tr>
        </thead>
        <tbody>
          <%= for {_k, lap} <- @laps do %>
            <tr>
              <%= for c <- laptime_columns do %>
                <td>
                  <%= Map.get(lap, c) %>
                </td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>

      <div class="pager">
        <a phx-target={@myself} phx-click="prev">
          <%= Icons.arrow_left %> Previous
        </a>
        <a phx-target={@myself} phx-click="next">
          Next <%= Icons.arrow_left %>
        </a>
      </div>

    </div>
    """
  end
end
