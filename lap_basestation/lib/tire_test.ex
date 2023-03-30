defmodule TireTest do
  @port "/dev/ttyUSB1"

  def parse_row(row) do
    Enum.reduce(row, [], fn
      temp, acc when is_list(acc) ->
        case Integer.parse(temp) do
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

  def init() do

    who = self()
    spawn_link(fn ->
      {:ok, pid} = Circuits.UART.start_link
      :ok = Circuits.UART.open(
        pid, @port, speed: 115200, active: false
      )

      Stream.each(read(pid), fn packet ->
        IO.inspect packet
      end)
      |> Stream.run()
    end)


  end
end