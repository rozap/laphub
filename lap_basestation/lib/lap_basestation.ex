defmodule LapBasestation do
  defmodule Handler do
    use GenServer
    require Logger

    @dimensions [
      {"P_O", :oil_pres, :psi},
      {"P_C", :coolant_pres, :psi_x10},
      {"T_O", :oil_temp, :degrees_f},
      {"T_C", :coolant_temp, :degrees_f},
      {"VBA", :voltage, :volt},
      {"RPM", :rpm, :rpm},
      {"MET", :met, :time},
      {"RSI", :rsi, :rsi},
      {"FLT", :fault, :none},
      {"GPS", :gps, :none}
    ]

    def dimensions, do: @dimensions

    def start_link(uart_pid, port, socket, id),
      do: GenServer.start_link(__MODULE__, [uart_pid, port, socket, id])

    def init([uart_pid, port, socket, id]) do
      Logger.info("Starting...")

      Circuits.UART.open(
        uart_pid,
        port,
        speed: 57600,
        active: true,
        framing: {Circuits.UART.Framing.Line, separator: "\n"}
      )

      {:ok, response, channel} = PhoenixClient.Channel.join(socket, "telemetry:#{id}")
      Logger.info("Connected to phx channel: #{inspect(response)}")
      {:ok, {false, channel}}
    end

    defp convert(unit, value)
         when unit in [
                :psi,
                :degrees_f,
                :volt,
                :rpm,
                :rsi,
                :met
              ] do
      {v, _} = Float.parse(value)

      if v > 0 do
        {:ok, v}
      end
    end

    defp convert(unit, value) when unit in [:psi_x10, :degrees_f_x10] do
      {v, _} = Float.parse(value)

      if v > 0 do
        {:ok, v / 10}
      end
    end

    defp convert(_, value), do: {:ok, value}

    defp loud(channel, label, value, unit) do
      Logger.info("#{label} : #{value} #{unit}")

      with {:ok, value} <- convert(unit, value) do
        :ok =
          PhoenixClient.Channel.push_async(channel, "sample", %{
            label: label,
            value: value
          })
      end
    end

    Enum.each(@dimensions, fn {prefix, name, units} ->
      defp dispatch("#{unquote(prefix)}:" <> value, {_, channel} = state) do
        loud(channel, unquote(name), value, unquote(units))
        state
      end
    end)

    defp dispatch("FLT:" <> fault, state) do
      Logger.warn("Fault: #{fault}")
      state
    end

    defp dispatch("init ok", {_, channel}) do
      Logger.info("Basestation has (re)connected")
      {true, channel}
    end

    defp dispatch(unknown, state) do
      Logger.warn("Unknown message #{unknown}")
      state
    end

    def handle_info({:circuits_uart, _port, message}, state) do
      state = dispatch(message, state)
      {:noreply, state}
    end
  end

  defp await_up(_, 50) do
    {:error, :socket_connect_timeout}
  end

  defp await_up(socket, attempt) do
    # Why is the phx client implemented like this...
    if PhoenixClient.Socket.connected?(socket) do
      :ok
    else
      :timer.sleep(500)
      await_up(socket, attempt + 1)
    end
  end

  def up(id, port \\ "/dev/ttyACM0") do
    {:ok, socket} = PhoenixClient.Socket.start_link(url: "ws://localhost:5000/socket/websocket")
    :ok = await_up(socket, 0)

    {:ok, pid} = Circuits.UART.start_link()
    Handler.start_link(pid, port, socket, id)
  end

  defp send_simulation(pid) do
    Enum.each(Handler.dimensions(), fn {prefix, name, units} ->
      value = :rand.uniform() * 100
      send(pid, {:circuits_uart, nil, "#{prefix}:#{value}"})
    end)

    :timer.sleep(500)
    send_simulation(pid)
  end

  def simulate(id) do
    {:ok, pid} = up(id)
    send_simulation(pid)
  end
end
