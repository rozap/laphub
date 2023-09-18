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
  alias Laphub.Laps.{ActiveSesh, Sesh}
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
      |> assign(:charts, default_charts())
      |> assign(:tz, "America/Los_Angeles")

    track = %Track{
      coords: [
        %{"lat" => 47.2538, "lon" => -123.1957}
      ],
      title: "The Ridge Motorsports Park"
    }

    socket =
      push_event(socket, "init", %{
        track: track
      })

    {:ok, socket}
  end

  defp default_charts() do
    [
      {"temperatures",
       [
         "coolant_temp"
         # "oil_temp"
       ]},
      {"pressures",
       [
         "oil_pres"
         # "coolant_pres"
       ]},
      {"volts", ["voltage"]},
      {"rpm", ["rpm"]}
      # {"speed", ["Speed (MPH)"]}
    ]
  end

  defp clamp_range(pid) do
    {from_key, to_key} = ActiveSesh.range(pid)
    clamped_from = Time.subtract(to_key, 60 * 60)
    IO.inspect({:from, from_key, :to, to_key})

    {max(clamped_from, from_key), to_key}
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
        <%= for {name, columns} <- @charts do %>
          <div>
            <h2><%= name %><%= inspect columns %></h2>
            <.live_component module={ChartComponent}
            id={"#{name}-chart"}
            columns={columns}
            name={name}
            pid={@pid}
            range={@range} />

          </div>
        <% end %>

        <.live_component
          module={LaptimesComponent}
          id="laptimes-table"
          pid={@pid}
        />
        <.live_component
          module={MapComponent}
          pid={@pid}
          id="map-wrap" />

      </div>
    </div>
    """
  end
end
