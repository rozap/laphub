defmodule LaphubWeb.Components.DateRangeComponent do
  use Phoenix.LiveView
  alias Laphub.Time
  import LaphubWeb.Components.WidgetUtil
  alias Laphub.Laps.ActiveSesh

  def mount(_, %{"sesh" => sesh}, socket) do
    ActiveSesh.subscribe(sesh)
    {:ok, pid} = ActiveSesh.get_or_start(sesh)

    socket =
      socket
      |> assign(:sesh, sesh)
      |> assign(:pid, pid)
      |> assign(:range, clamp_range(pid))
      |> assign(:tz, "America/Los_Angeles")
      |> assign(:state, "realtime")

    {:ok, socket}
  end

  defp send_state(socket) do
    push_event(socket, "set_widget_state", %{"state" => socket.assigns.state})
  end

  def handle_event("set_range", range, socket) do
    IO.inspect({:set_Range, range})

    %{
      "from" => from,
      "to" => to,
      "type" => "unix_second_range"
    } = range

    socket = assign(socket, :range, {Time.second_to_key(from), Time.second_to_key(to)})
    {:noreply, socket}
  end

  def handle_event("set_state", %{"state" => state}, socket) do
    changed? = state != socket.assigns.state

    socket =
      socket
      |> assign(:state, state)

    socket =
      if changed? do
        send_state(socket)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("resume", _, socket) do
    socket =
      socket
      |> assign(:state, "realtime")
      |> send_state()

    {:noreply, socket}
  end

  def handle_event("pause", _, socket) do
    socket =
      socket
      |> assign(:state, "paused")
      |> send_state()

    {:noreply, socket}
  end

  def handle_event(which, %{"value" => local_iso} = wut, socket)
      when which in ["set_from_range", "set_to_range"] do
    {from_key, to_key} = socket.assigns.range

    new_key =
      local_iso
      |> NaiveDateTime.from_iso8601!()
      |> DateTime.from_naive!(socket.assigns.tz)
      |> DateTime.shift_zone!("Etc/UTC")
      |> Time.to_key()

    new_range =
      {from_k, to_k} =
      case which do
        "set_from_range" -> {new_key, to_key}
        "set_to_range" -> {from_key, new_key}
      end

    socket =
      push_event(socket, "set_range", %{
        "range" => %{
          "type" => "unix_second_range",
          "from" => Time.key_to_second(from_k),
          "to" => Time.key_to_second(to_k)
        }
      })

    IO.inspect {:new_range, from_k, to_k}

    {:noreply, assign(socket, :range, new_range)}
  end

  def render(assigns) do
    to_datetime = fn key ->
      naive = Time.key_to_datetime(key)
      {:ok, dt} = DateTime.from_naive(naive, "Etc/UTC")
      DateTime.shift_zone!(dt, assigns.tz)
    end

    {from, to} = assigns.range

    from_d = to_datetime.(from)
    to_d = to_datetime.(to)

    seconds_diff = DateTime.diff(to_d, from_d, :second)
    with_day = seconds_diff > 60 * 60 * 24

    make_time_input = fn which, local_time ->
      local_value =
        local_time
        |> DateTime.to_iso8601()
        |> String.slice(0, 19)

      ~H"""
        <input
          value={local_value}
          phx-value-tz={@tz}
          phx-blur={"set_#{which}"}
          type="datetime-local" step="5" />
      """
    end

    ~H"""
    <div class="date-range" phx-hook="DateRange" id="date-range">
      <div class="date-picker from-date">
        <%= make_time_input.("from_range", from_d) %>
      </div>

      <%= if @state != "realtime" do %>
        <button class="btn" phx-click="resume">
          Resume
        </button>
      <% end %>
      <%= if @state != "paused" do %>
        <button class="btn" phx-click="pause">
          Pause
        </button>
      <% end %>

      <div class="date-picker to-date">
        <%= make_time_input.("to_range", to_d) %>
      </div>

    </div>
    """
  end
end
