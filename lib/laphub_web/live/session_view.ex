defmodule LaphubWeb.SessionLive do
  use LaphubWeb, :live_view
  import LaphubWeb.Components.CommonComponents
  require Logger

  alias LaphubWeb.Components.{
    DateRangeComponent,
    ColumnSelector,
    ChartComponent,
    MapComponent,
    LaptimesComponent,
    FaultComponent,
    TrackAddictComponent
  }

  alias Laphub.Laps.Track
  alias Laphub.{Time, Laps, Repo}
  alias Laphub.Laps.{ActiveSesh, Sesh, Dashboard}
  alias Laphub.Laps.Timeseries

  def mount(%{"session_id" => id}, %{"user" => user}, socket) do
    sesh = Laps.my_sesh(user.id, id)

    ActiveSesh.subscribe(sesh)
    {:ok, pid} = ActiveSesh.get_or_start(sesh)

    socket =
      socket
      |> assign(:sesh, sesh)
      |> assign(:pid, pid)
      |> assign(:range, clamp_range(pid))
      |> assign(:columns, ActiveSesh.columns(pid))
      |> assign(:dashboard, Dashboard.default())
      |> assign(:tz, "America/Los_Angeles")

    {:ok, socket}
  end


  defp clamp_range(pid) do
    {from_key, to_key} = ActiveSesh.range(pid)
    clamped_from = Time.subtract(to_key, 60 * 60)
    from = max(clamped_from, from_key)
    IO.inspect({:from, Time.key_to_datetime(from) |> NaiveDateTime.to_iso8601(), :to, Time.key_to_datetime(to_key) |> NaiveDateTime.to_iso8601()})

    {from, to_key}
  end

  defp print_range({from, to} = range) do
    f = Time.key_to_datetime(from) |> NaiveDateTime.to_iso8601()
    t = Time.key_to_datetime(to) |> NaiveDateTime.to_iso8601()
    Logger.info("Range is set to #{f} to #{t}")

    range
  end

  def handle_event("set_range", range_like, socket) do
    socket =
      socket
      |> assign(:range, print_range(Time.to_range(range_like, socket.assigns.tz)))

    {:noreply, socket}
  end

  def handle_info({DateRangeComponent, new_range}, socket) do
    socket =
      socket
      |> assign(:range, print_range(new_range))

    {:noreply, socket}
  end

  def handle_info({:push_event, kind, payload}, socket) do
    {:noreply, push_event(socket, kind, payload)}
  end

  def handle_info({ActiveSesh, {:change, columns, range}}, socket) do
    {:noreply, socket}
  end

  def handle_info({ActiveSesh, {:append, key, dimensions}}, socket) do
    Logger.info("append #{key} #{inspect(dimensions)}")

    socket =
      Enum.reduce(dimensions, socket, fn {column, value}, socket ->
        push_event(socket, "append_rows:#{column}", %{rows: [%{t: key, value: value}]})
      end)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="session">
      <div class="column-selector">
        <.live_component
          module={ColumnSelector}
          id="column-selector"
          columns={@columns}
          selected_columns={MapSet.new(@columns)}
        />
      </div>

      <div class="lap-viewer">
        <div class="toolbar">
          <.live_component
            module={DateRangeComponent}
            id="session-time-range"
            range={@range}
            tz={"America/Los_Angeles"}/>
        </div>

        <div class="widgets">
          <.live_component
            module={FaultComponent}
            id="fault-wrap"
          />
        </div>
        <%= for w <- @dashboard.widgets do %>
          <div>
            <p><%= w.title %><%= inspect w.columns %></p>

            <%
              w_mod = case w.component do
                "chart" -> ChartComponent
                "map" -> MapComponent
                "laptimes" -> LaptimesComponent
              end
            %>

            <.live_component module={w_mod}
              id={"#{w.title}-#{w_mod}"}
              columns={w.columns}
              name={w.title}
              pid={@pid}
              range={@range} />
          </div>
        <% end %>


      </div>
    </div>
    """
  end
end
