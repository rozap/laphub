defmodule LaphubWeb.Components.LaptimesComponent do
  use Phoenix.LiveComponent
  alias Laphub.Laps.{Timeseries, ActiveSesh}
  import LaphubWeb.Components.Util
  alias LaphubWeb.Icons
  alias Laphub.Time
  alias Laphub.Time.DurationFormatter

  @page_size 20

  def id(), do: "laptimes-component"

  def mount(socket) do
    socket =
      socket
      |> assign(:page, 0)
      |> assign(:pid, nil)
      |> assign(:decorations, %{})

    {:ok, socket}
  end

  def update(assigns, socket) do
    new_socket = assign(socket, assigns)

    if socket.assigns.pid != new_socket.assigns.pid do
      compute_decorations(new_socket)
    end


    {:ok, fetch(new_socket)}
  end

  defp compute_decorations(socket) do
    owner = self()
    spawn_link(fn ->
      decorations =
        socket
        |> laps()
        |> into_times(socket)
        |> Enum.reduce(%{}, fn lap, acc ->
          time = lap.time

          case Map.get(acc, :best) do
            nil -> Map.put(acc, :best, lap)
            %{time: t} when t > time -> Map.put(acc, :best, lap)
            _ -> acc
          end
        end)

      send_update(owner, __MODULE__, id: socket.assigns.id, decorations: decorations)
    end)
  end

  defp laps(socket) do
    ActiveSesh.stream(socket.assigns.pid, "lap", fn
      nil ->
        []
      kv ->
        Timeseries.all(kv)
    end)
  end

  defp into_times(lap_stream, socket) do
    pid = socket.assigns.pid
    columns = ActiveSesh.columns(pid)
    Stream.transform(lap_stream, nil, fn
      {key, _lapno}, nil ->
        {[], Time.key_to_millis(key)}

      {key, lapno}, last ->

        driver = if "drivers" in columns do
          ActiveSesh.stream(pid, "drivers", fn db ->
            Timeseries.all_reversed(db)
            |> Stream.filter(fn {k, _} -> k < key end)
            |> Enum.take(1)
            |> case do
              [{_k, driver}] -> driver
              _ -> nil
            end
          end)
        else
          nil
        end

        current = Time.key_to_millis(key)
        time = current - last

        {[
           %{
             lapno: lapno,
             time: time,
             formatted: DurationFormatter.format(time),
             driver: driver
           }
         ], current}
    end)
  end

  defp fetch(socket) do
    columns = ActiveSesh.columns(socket.assigns.pid)
    page = socket.assigns.page

    laps =
      if "lap" in columns do
        socket
        |> laps()
        |> Stream.drop(page * @page_size)
        |> into_times(socket)
        |> Enum.take(@page_size)
      else
        []
      end

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
  defp get_column_name(:formatted), do: "Time"
  defp get_column_name(:driver), do: "Driver"


  def render(assigns) do
    laptime_columns = [:lapno, :formatted, :driver]

    ~H"""
    <div class="laptimes-component" id={id()}>
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
          <% best = Map.get(@decorations, :best) %>
          <%= for lap <- @laps do %>

            <tr class={classnames([{"fast-lap", best && best.lapno == lap.lapno}])}>
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
