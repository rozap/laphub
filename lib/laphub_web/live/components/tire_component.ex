defmodule LaphubWeb.Components.TireComponent do
  use Phoenix.LiveView
  import LaphubWeb.Components.Util
  alias Laphub.Laps.{ActiveSesh}
  alias Laphub.Laps.Timeseries
  alias Phoenix.PubSub


  defmodule TireTest do
    @port "/dev/ttyUSB1"

    def parse_row(row) do
      Enum.reduce(row, [], fn
        temp, acc when is_list(acc) ->
          case Float.parse(temp) do
            {i, ""} -> [i | acc]
            _ -> {:error, :nonint}
          end
        _, acc -> acc
      end)
      |> case do
        {:error, :nonint} ->
          IO.puts("Skipped packet...")
          []
        ok -> [Enum.reverse(ok)]
      end
    end

    def parse(rows) do
      case Enum.flat_map(rows, &parse_row/1) do
        result when is_list(result) and length(result) == 4 ->
          [result]
        _ ->
          []
      end

    end

    def packetize(<<>>, leftover, packets) do
      result =
        packets
        |> Enum.reverse
        |> Enum.flat_map(&parse/1)
      {result, leftover}
    end

    def packetize("\r\n" <> rest, buf, packets) do
      packet = String.split(buf, ",")
      |> Enum.chunk_every(16, 16, [])
      |> Enum.take(4)
      packetize(rest, <<>>, [packet | packets])
    end

    def packetize(<<c::binary-size(1), rest::binary>>, buf, packets) do
      packetize(rest, buf <> c, packets)
    end

    def read(from) do
      Stream.resource(
        fn -> <<>> end,
        fn buf ->
          {:ok, next} = Circuits.UART.read(from)
          packetize(buf <> next, <<>>, [])
        end,
        fn _ -> :ok end
      )
    end

    def init(who) do
      spawn_link(fn ->
        {:ok, pid} = Circuits.UART.start_link
        :ok = Circuits.UART.open(
          pid, @port, speed: 115200, active: false
        )

        Stream.each(read(pid), fn packet ->
          PubSub.broadcast(
            Laphub.InternalPubSub,
            "tiretest",
            {:measure, packet}
          )
        end)
        |> Stream.run()
      end)
    end
  end

  def mount(_, _, socket) do
    PubSub.subscribe(
      Laphub.InternalPubSub,
      "tiretest"
    )
    socket =
      socket
      |> assign(:measurement, nil)
    {:ok, socket}
  end


  def handle_info({:measure, m}, socket) do
    {:noreply, assign(socket, :measurement, m)}
  end

  defp to_color(t) do
    max_value = 60
    min_value = 10

    v = (t - min_value) / (max_value - min_value)


    aR = 0
    aG = 0
    aB = 255

    bR = 255
    bG = 0
    bB = 0

    red   = (bR - aR) * v + aR
    green = (bG - aG) * v + aG
    blue  = (bB - aB) * v + aB

    "rgb(#{red}, #{green}, #{blue})"
  end

  def render(assigns) do
    IO.inspect(self())
    ~H"""
    <div id="tires" class="tire-temperatures">
      <%= if @measurement do %>
        <%= for row <- @measurement do %>
          <div class="rows">
            <%= for value <- row do %>
              <div class="pixel" style={"background-color: #{to_color(value)}"}>
              </div>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
