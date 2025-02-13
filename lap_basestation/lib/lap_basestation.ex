defmodule LapBasestation do
  defmodule Handler do
    use GenServer
    @singular "sample"
    @multi "samples"

    @dimensions [
      {"P_C", :coolant_pres, :psi_x10, @singular},
      {"T_O", :oil_temp, :degrees_f, @singular},
      {"T_C", :coolant_temp, :degrees_f, @singular},
      {"VBA", :voltage, :volt, @singular},
      {"P_O", :oil_pres, :psi, @singular},
      {"P_F", :fuel_pres, :psi, @singular},
      {"RPM", :rpm, :rpm, @singular},
      {"MET", :met, :time, @singular},
      {"RSI", :rsi, :rsi, @singular},
      {"FLT", :fault, :none, @singular},
      {"GPS", :gps, :none, @multi},
      {"SPD", :speed, :mph, @multi},
      {"GAS", :fuel_level, :pct, @singular},
      {"S_E", :engine_status, :bitfield, @singular},
      {"ADV", :advance, :degrees, @singular},
      {"O_2", :air_fuel_ratio, :number, @singular},
      {"IAT", :intake_air_temp, :degrees_f, @singular},
      {"SLS", :sync_loss_count, :number, @singular},
      {"MAP", :vacuum, :kpa, @singular},
      {"V_E", :volumetric_efficiency, :pct, @singular},
      {"AFT", :air_fuel_target, :number, @singular},
      {"TPS", :throttle_position, :pct, @singular},
      {"S_P", :engine_protecc, :bitfield, @singular},
      {"FAN", :fan_duty, :number, @singular},
      {"S_1", :status_1, :bitfield, @singular},
      {"S_3", :status_3, :bitfield, @singular},
      {"S_4", :status_4, :bitfield, @singular}
    ]

    def dimensions, do: @dimensions

    def start_link(uart_pid, port, socket, id),
      do: GenServer.start_link(__MODULE__, [uart_pid, port, socket, id])

    def init([uart_pid, port, socket, id]) do
      IO.puts("Starting...")

      Circuits.UART.open(
        uart_pid,
        port,
        speed: 57600,
        active: true,
        framing: {Circuits.UART.Framing.Line, separator: "\n"}
      )

      {:ok, response, channel} = PhoenixClient.Channel.join(socket, "telemetry:#{id}")
      IO.puts("Connected to phx channel: #{inspect(response)}")
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

    defp loud(channel, event_name, label, value, unit) do
      if String.valid?(value) do
        plabel = String.pad_leading(to_string(label), 28)
        pvalue = String.pad_trailing(String.trim_leading(to_string(value), "0"), 16)
        punit = String.pad_leading(to_string(unit), 16)
        IO.puts("#{plabel} #{pvalue} #{punit}")

        with {:ok, value} <- convert(unit, value) do
          :ok =
            PhoenixClient.Channel.push_async(channel, event_name, %{
              label: label,
              value: value
            })
        end
      else
        IO.puts("Invalid string, not utf8")
      end
    end

    Enum.each(@dimensions, fn {prefix, name, units, event_name} ->
      defp dispatch("#{unquote(prefix)}:" <> value, {_, channel} = state) do
        value = String.trim(value, "\r")
        loud(channel, unquote(event_name), unquote(name), value, unquote(units))
        state
      end
    end)

    defp dispatch("FLT:" <> fault, state) do
      IO.puts("Fault: #{fault}")
      state
    end

    defp dispatch("init ok", {_, channel}) do
      IO.puts("Basestation has (re)connected")
      {true, channel}
    end

    defp dispatch("\r", state) do
      IO.puts(Enum.join(List.duplicate("-", 80), ""))
      state
    end

    defp dispatch(unknown, state) do
      IO.puts("")
      IO.puts("Unknown message: #{inspect unknown}")
      state
    end

    def handle_info({:circuits_uart, _port, message}, state) do
      state = message |> dispatch(state)
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
    {:ok, socket} = PhoenixClient.Socket.start_link(
      url: "ws://localhost:5000/socket/websocket"
    )
    :ok = await_up(socket, 0)

    {:ok, pid} = Circuits.UART.start_link()
    Handler.start_link(pid, port, socket, id)
  end
end
