defmodule LaphubWeb.Components.ChartComponent do
  use Phoenix.LiveComponent
  import LaphubWeb.Components.Util
  alias Laphub.Laps.{ActiveSesh}
  alias Laphub.Laps.Timeseries

  defp fetch(assigns, socket) do
    {from_key, to_key} = assigns.range

    parent = self()

    spawn(fn ->
      Enum.each(assigns.columns, fn column ->
        rows =
          ActiveSesh.stream(assigns.pid, column, fn
            nil ->
              []

            kv ->
              Timeseries.walk_forward(kv, from_key)
          end)
          |> Stream.take_while(fn {key, _} ->
            key <= to_key
          end)
          |> Enum.map(fn {key, value} ->
            %{t: key, value: value}
          end)

        send(parent, {:push_event, "set_rows:#{column}", %{column: column, rows: rows}})
      end)
    end)

    socket
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(fetch(assigns, socket), assigns)}
  end

  def render(assigns) do
    ~H"""
    <div phx-hook="Chart" class="chart" id={@name}>


    </div>
    """
  end
end
