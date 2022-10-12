defmodule LaphubWeb.SessionLive do
  use LaphubWeb, :live_view
  import LaphubWeb.Components.CommonComponents
  require Logger

  alias LaphubWeb.Components.{
    DateRangeComponent,
    ColumnSelectorComponent,
    ChartComponent,
    MapComponent,
    LaptimesComponent,
    FaultComponent
  }

  alias Laphub.Integrations.TrackAddictLive
  alias Laphub.Laps.Track
  alias Laphub.{Time, Laps, Repo}
  alias Laphub.Laps.{ActiveSesh, Sesh}
  alias Laphub.Laps.Timeseries



  def render(assigns) do
    ~H"""
    <div>
      <div>
        <.live_component
          module={ColumnSelectorComponent}
          id="column-selector"
          columns={@columns}
          selected_columns={MapSet.new(@columns)}
        />
        <.live_component module={DateRangeComponent} id="session-time-range" range={@range} tz={"America/Los_Angeles"}/>
      </div>
      <div class="lap-view-main">
        <.live_component
          module={FaultComponent}
          id="fault-wrap"
        />
        <.live_component
          module={LaptimesComponent}
          id="laptimes-table"
          pid={@pid}
        />
        <.live_component
          module={MapComponent}
          pid={@pid}
          id="map-wrap" />

        <%= for {name, columns} <- @charts do %>
          <.live_component module={ChartComponent}
            id={"#{name}-chart"}
            columns={columns}
            name={name}
            pid={@pid}
            range={@range} />
        <% end %>
      </div>

      <div class="laps-settings">
        <%= label(:client_id, :client_id, "Track Addict Client ID") %>
        <%= text_input :client_id, :client_id, value: "131355221", phx_keyup: "settings:client_id" %>
        <.primary_button label="Startf" click="settings:start_client" />
      </div>
    </div>
    """
  end

  def mount(%{"session_id" => id}, %{"user" => user}, socket) do
    sesh = Laps.my_sesh(user.id, id)

    ActiveSesh.subscribe(sesh)
    {:ok, pid} = ActiveSesh.get_or_start(sesh)

    socket =
      socket
      |> assign(:client_id, "131355221")
      |> assign(:sesh, sesh)
      |> assign(:pid, pid)
      |> assign(:range, clamp_range(pid) |> IO.inspect())
      |> assign(:columns, ActiveSesh.columns(pid))
      |> assign(:charts, default_charts())
      |> assign(:tz, "America/Los_Angeles")

    track = %Track{
      coords: [
        %{"lat" => 45.366111, "lon" => -120.743056}
      ],
      title: "Oregon Raceway Park"
    }

    socket =
      push_event(socket, "init", %{
        track: track
      })

    {:ok, socket}
  end


  defp default_charts() do
    [
      {"temperatures", ["coolant_temp", "oil_temp"]},
      {"pressures", ["oil_pres", "coolant_pres"]},
      {"volts", ["voltage"]},
      {"rpm", ["rpm"]},
      {"speed", ["Speed (MPH)"]}
    ]
  end

  defp clamp_range(pid) do
    {from_key, to_key} = ActiveSesh.range(pid)
    clamped_from = Time.subtract(to_key, 60 * 60)
    {max(clamped_from, from_key), to_key}
  end

  def handle_event("settings:client_id", %{"value" => value}, socket) do
    {:noreply, assign(socket, :client_id, value)}
  end

  def handle_event("settings:start_client", _, socket) do
    {:ok, pid} = TrackAddictLive.start_link(socket.assigns.client_id, socket.assigns.sesh)
    {:noreply, socket}
  end

  def handle_event("set_range", range_like, socket) do
    socket =
      socket
      |> assign(:range, Time.to_range(range_like, socket.assigns.tz))

    {:noreply, socket}
  end

  def handle_info({DateRangeComponent, new_range}, socket) do
    socket =
      socket
      |> assign(:range, new_range)

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

  def handle_info({TrackAddictLive, payload}, socket) do
    IO.inspect({:coords, payload})
    {:noreply, socket}
  end
end
