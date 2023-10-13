defmodule LaphubWeb.Components.Widget do
  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveView
      alias Laphub.Laps.{ActiveSesh}
      alias Laphub.Laps.Timeseries
      alias Laphub.Time
      alias Laphub.Laps.{Sesh, Dashboard}
      require Logger
      import LaphubWeb.Components.WidgetUtil

      def mount(_, %{"user" => user, "sesh" => sesh, "widget" => widget}, socket) do
        ActiveSesh.subscribe(sesh)
        {:ok, pid} = ActiveSesh.get_or_start(sesh)

        socket =
          socket
          |> assign(:sesh, sesh)
          |> assign(:pid, pid)
          |> assign(:widget, widget)
          |> assign(:range, clamp_range(pid))
          |> assign(:dashboard, Dashboard.default())
          |> assign(:tz, "America/Los_Angeles")
          |> fetch()

        {:ok, socket} = init(socket)

        {:ok, socket}
      end

      def init(socket) do
        {:ok, socket}
      end

      defp print_range({from, to} = range, socket) do
        f = Time.key_to_datetime(from) |> NaiveDateTime.to_iso8601()
        t = Time.key_to_datetime(to) |> NaiveDateTime.to_iso8601()
        Logger.info("Range is set to #{f} to #{t} for ")

        range
      end

      def handle_event("set_range", range_like, socket) do
        socket =
          socket
          |> assign(:range, print_range(Time.to_range(range_like, socket.assigns.tz), socket))
          |> fetch

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

      # def update(assigns, socket) do

      #   {:ok, assign(fetch(assigns, socket), assigns)}
      # end


      def fetch(socket) do
        assigns = socket.assigns
        {from_key, to_key} = assigns.range

        # IO.inspect(
        #   {:sending_rows, Time.key_to_datetime(from_key) |> NaiveDateTime.to_iso8601(), :to,
        #    Time.key_to_datetime(to_key) |> NaiveDateTime.to_iso8601()}
        # )

        parent = self()

        spawn(fn ->
          Enum.each(assigns.widget.columns, fn column ->
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

            IO.inspect {:set_rows, socket.assigns.widget.title, column}
            send(parent, {:push_event, "set_rows:#{column}", %{column: column, rows: rows}})
          end)
        end)

        socket
      end

      defoverridable init: 1
    end
  end
end
