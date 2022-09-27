defmodule LaphubWeb.SessionLive do
  use LaphubWeb, :live_view
  import LaphubWeb.Components.CommonComponents
  alias Laphub.Integrations.TrackAddictLive
  alias Laphub.Laps.Track
  alias Laphub.{Laps, Repo}
  alias Laphub.Laps.{ActiveSesh, Sesh}
  alias Laphub.Laps.Timeseries

  def render(assigns) do
    ~H"""
    <div id="LapViewer" phx-hook="LapViewer">
      <div>
        <.date_range range={@range} />
      </div>
      <div class="lap-view-main">
          <div id="no-map"></div>

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
      |> assign(:range, clamp_range(pid))
      |> assign(:columns, ActiveSesh.columns(pid))

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

  defp clamp_range(pid) do
    {from_key, to_key} = ActiveSesh.range(pid)
    clamped_from = ActiveSesh.subtract(to_key, 60 * 60)
    {max(clamped_from, from_key), to_key}
  end

  def handle_event("settings:client_id", %{"value" => value}, socket) do
    {:noreply, assign(socket, :client_id, value)}
  end

  def handle_event("settings:start_client", _, socket) do
    {:ok, pid} = TrackAddictLive.start_link(socket.assigns.client_id, socket.assigns.sesh)
    {:noreply, socket}
  end

  def handle_event("component:" <> which, %{"value" => value}, socket)
      when which in ["set_from_range", "set_to_range"] do
    IO.inspect(value)
    {from_key, to_key} = socket.assigns.range
    {:ok, d} = NaiveDateTime.from_iso8601(value)
    new_key = naive_datetime_to_key(d, socket)

    new_range =
      case which do
        "set_from_range" -> {new_key, to_key}
        "set_to_range" -> {from_key, new_key}
      end

    socket = fetch(assign(socket, :range, new_range))
    {:noreply, socket}
  end

  def naive_datetime_to_key(n, _socket) do
    {:ok, dt} = DateTime.from_naive(n, "America/Los_Angeles")
    ActiveSesh.datetime_to_key(dt)
  end

  defp fetch(socket) do
    {from_key, to_key} = socket.assigns.range

    rows =
      ActiveSesh.stream(socket.assigns.pid, fn kv ->
        Timeseries.walk_forward(kv, from_key)
      end)
      |> Stream.take_while(fn {key, _} ->
        key <= to_key
      end)
      |> Enum.map(fn {key, series} ->
        %{t: key, series: series}
      end)

    push_event(socket, "set_rows", %{rows: rows})
  end

  def handle_info(:fetch, socket) do
    {:noreply, fetch(socket)}
  end

  def handle_info({ActiveSesh, {:change, columns, range}}, socket) do
    {:noreply, socket}
  end

  def handle_info({ActiveSesh, {:append, key, dimensions}}, socket) do
    socket = push_event(socket, "append", %{rows: [%{t: key, series: dimensions}]})
    {:noreply, socket}
  end

  def handle_info({TrackAddictLive, payload}, socket) do
    IO.inspect({:coords, payload})
    {:noreply, socket}
  end
end
