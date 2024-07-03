defmodule Laphub.Video.VideoServer do
  alias Membrane.RTMP.Source.TcpServer
  alias Laphub.Laps.Sesh
  @local_ip {127, 0, 0, 1}

  defmodule TcpServerRegistry do
    require Logger

    def all() do
      Registry.lookup(__MODULE__, :port)
    end

    def register(port) do
      Logger.info("#{inspect(self())} is running at #{port}")
      Registry.register(__MODULE__, :port, port)
    end
  end

  def next_free_port() do
    used = Enum.map(TcpServerRegistry.all(), fn {_pid, port} -> port end) |> MapSet.new()
    Enum.find(9000..9999, fn port ->
      not MapSet.member?(used, port)
    end)
  end

  def start_link(sesh, port) do
    path = path_to(sesh)
    File.mkdir_p!(path)

    spawn_link(fn ->
      tcp_server_options = %TcpServer{
        port: port,
        listen_options: [
          :binary,
          packet: :raw,
          active: false,
          ip: @local_ip
        ],
        socket_handler: fn socket ->
          IO.inspect({:socket_connect, socket})

          {:ok, _sup, pid} =
            Membrane.Pipeline.start_link(
              Laphub.Video.Pipeline,
              %{
                path: path,
                socket: socket
              }
            )

          {:ok, pid}
        end
      }

      TcpServer.start_link(tcp_server_options)

      TcpServerRegistry.register(port)
      :timer.sleep(:infinity)
    end)
  end

  def path_to(%Sesh{id: id}) do
    "/tmp/output/sesh_#{id}"
  end

  def path_to(%Sesh{} = s, filename) do
    Path.join([path_to(s), filename])
  end
end
