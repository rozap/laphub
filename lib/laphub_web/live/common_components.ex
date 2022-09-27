defmodule LaphubWeb.Components.CommonComponents do
  use Phoenix.LiveComponent

  def primary_button(assigns) do
    ~H"""
    <a phx-click={@click}><%= @label %></a>
    """
  end

  def date_string(d) do
    "#{d.month}/#{d.day}/#{d.year}"
  end

  def date(assigns) do
    %{date: d} = assigns

    ~H"""
      <%= date_string(d) %>
    """
  end

  def date_range(assigns) do
    to_datetime = fn key ->
      Laphub.Laps.ActiveSesh.key_to_datetime(key)
    end

    {from, to} = assigns.range

    from_d = to_datetime.(from)
    to_d = to_datetime.(to)

    seconds_diff = DateTime.diff(to_d, from_d, :second)
    with_day = seconds_diff > 60 * 60 * 24

    make_time_input = fn which, d ->
      value = DateTime.to_iso8601(d) |> String.slice(0, 19)
      # TODO: turn these into the correct TZ offset

      ~H"""
        <input
          value={value}
          phx-blur={"component:set_#{which}"}
          type="datetime-local" step="5" />
      """
    end

    ~H"""
    <div class="date-range">
      <div class="date-picker from-date">
        <%= make_time_input.("from_range", from_d) %>
      </div>
      <div class="slider">
        <input
          type="range"
          id="scrub"
          name="scrub"
          min="0" max="1000">
      </div>
      <div class="date-picker to-date">
        <%= make_time_input.("to_range", to_d) %>
      </div>

    </div>
    """
  end
end
