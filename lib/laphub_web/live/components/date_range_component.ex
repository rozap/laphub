defmodule LaphubWeb.Components.DateRangeComponent do
  use Phoenix.LiveComponent
  alias Laphub.Time

  def handle_event("component:" <> which, %{"value" => local_iso} = wut, socket)
      when which in ["set_from_range", "set_to_range"] do
    {from_key, to_key} = socket.assigns.range

    new_key =
      local_iso
      |> NaiveDateTime.from_iso8601!()
      |> DateTime.from_naive!(socket.assigns.tz)
      |> DateTime.shift_zone!("Etc/UTC")
      |> Time.to_key()

    new_range =
      case which do
        "set_from_range" -> {new_key, to_key}
        "set_to_range" -> {from_key, new_key}
      end

    send(self, {__MODULE__, new_range})
    {:noreply, socket}
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
          phx-target={@myself}
          phx-blur={"component:set_#{which}"}
          type="datetime-local" step="5" />
      """
    end

    ~H"""
    <div class="date-range">
      <div class="date-picker from-date">
        <%= make_time_input.("from_range", from_d) %>
      </div>

      <div class="date-picker to-date">
        <%= make_time_input.("to_range", to_d) %>
      </div>

    </div>
    """
  end
end
