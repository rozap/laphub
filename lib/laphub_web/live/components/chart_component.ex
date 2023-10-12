defmodule LaphubWeb.Components.ChartComponent do
  use LaphubWeb.Components.Widget

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div phx-hook="Chart" class="chart" id={@name}>
    </div>
    """
  end
end
