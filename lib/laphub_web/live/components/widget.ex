defmodule LaphubWeb.Components.Widget do
  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent
      alias Laphub.Laps.{ActiveSesh}
      alias Laphub.Laps.Timeseries
      alias Laphub.Time

      def update(assigns, socket) do
        {:ok, assign(fetch(assigns, socket), assigns)}
      end


      def fetch(assigns, socket) do
        {from_key, to_key} = assigns.range

        IO.inspect(
          {:sending_rows, Time.key_to_datetime(from_key) |> NaiveDateTime.to_iso8601(), :to,
           Time.key_to_datetime(to_key) |> NaiveDateTime.to_iso8601()}
        )

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

            IO.inspect({:push_event, "set_rows:#{column}", length(rows)})
            send(parent, {:push_event, "set_rows:#{column}", %{column: column, rows: rows}})
          end)
        end)

        socket
      end
    end
  end
end
