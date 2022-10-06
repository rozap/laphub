defmodule LaphubWeb.SessionLive do
  use LaphubWeb, :live_view
  import LaphubWeb.Components.CommonComponents
  alias LaphubWeb.Components.CommonComponents.DateRangeComponent
  alias Laphub.Integrations.TrackAddictLive
  alias Laphub.Laps.Track
  alias Laphub.{Time, Laps, Repo}
  alias Laphub.Laps.{ActiveSesh, Sesh}
  alias Laphub.Laps.Timeseries

  def render(assigns) do
    ~H"""
    <div id="LapViewer" phx-hook="LapViewer">
      <div>
        <%= inspect(@columns) %>
        <.live_component module={DateRangeComponent} id="session-time-range" range={@range} tz={"America/Los_Angeles"}/>
      </div>
      <div class="lap-view-main">
          <div id="no-map"></div>

          <div class="chart" id="speed"></div>
          <div class="chart" id="temperatures"></div>
          <div class="chart" id="pressures"></div>
          <div class="chart" id="volts"></div>
          <div class="chart" id="rpm"></div>
          <div class="chart" id="rsi"></div>

        </div>

      <div class="laps-settings">
        <%= label(:client_id, :client_id, "Track Addict Client ID") %>
        <%= text_input :client_id, :client_id, value: "131355221", phx_keyup: "settings:client_id" %>
        <.primary_button label="Start" click="settings:start_client" />
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
      |> assign(:selected_columns, default_columns())
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

    send(self, :fetch)

    {:ok, socket}
  end

  defp default_columns() do
    MapSet.new([
      "Speed (MPH)",
      "coolant_pres",
      "coolant_temp",
      "oil_pres",
      "oil_temp",
      "rpm",
      "voltage"
    ])
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

  defp fetch_all(socket) do
    ActiveSesh.columns(socket.assigns.pid)
    |> Enum.filter(fn c -> MapSet.member?(socket.assigns.selected_columns, c) end)
    |> IO.inspect()
    |> Enum.reduce(socket, fn column, socket ->
      fetch(column, socket)
    end)
  end

  defp fetch(column, socket) do
    {from_key, to_key} = socket.assigns.range

    rows =
      ActiveSesh.stream(socket.assigns.pid, column, fn kv ->
        Timeseries.walk_forward(kv, from_key)
      end)
      |> Stream.take_while(fn {key, _} ->
        key <= to_key
      end)
      |> Enum.map(fn {key, value} ->
        %{t: key, value: value}
      end)

    IO.inspect({:set_rows, column})
    push_event(socket, "set_rows", %{column: column, rows: rows})
  end

  def handle_info({DateRangeComponent, new_range}, socket) do
    socket =
      socket
      |> assign(:range, new_range)
      |> fetch_all

    {:noreply, socket}
  end

  def handle_event("set_range", range_like, socket) do
    socket =
      socket
      |> assign(:range, Time.to_range(range_like, socket.assigns.tz))
      |> fetch_all

    {:noreply, socket}
  end

  def handle_info(:fetch, socket) do
    {:noreply, fetch_all(socket)}
  end

  def handle_info({ActiveSesh, {:change, columns, range}}, socket) do
    {:noreply, socket}
  end

  def handle_info({ActiveSesh, {:append, key, dimensions}}, socket) do
    Enum.reduce(dimensions, socket, fn {column, value} ->
      push_event(socket, "append", %{rows: [%{t: key, series: dimensions}]})
    end)

    {:noreply, socket}
  end

  def handle_info({TrackAddictLive, payload}, socket) do
    IO.inspect({:coords, payload})
    {:noreply, socket}
  end
end
