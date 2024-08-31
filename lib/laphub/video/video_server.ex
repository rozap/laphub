defmodule Laphub.Video.VideoServer do
  alias Membrane.RTMP.Source.TcpServer
  alias Laphub.Laps.Sesh
  use GenServer
  require Logger
  alias Phoenix.PubSub
  @local_ip {127, 0, 0, 1}

  defmodule VideoServerRegistry do
    require Logger

    def all_sesh() do
      Registry.lookup(__MODULE__, :sesh)
    end

    def register(sesh) do
      Registry.register(__MODULE__, :sesh, sesh)
    end
  end

  def start_link(sesh) do
    GenServer.start_link(__MODULE__, [sesh])
  end

  defmodule RTMPServer do
    use GenServer
    @port 9000

    def start_link(_) do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init(_) do
      {:ok, server} =
        Membrane.RTMP.Server.start_link(
          handler: %Membrane.RTMP.Source.ClientHandler{controlling_process: self()},
          port: @port,
          use_ssl?: false
        )

      {:ok, server}
    end

    def handle_call({:subscribe, app, stream_key, who}, _, server) do
      GenServer.cast(server, {:subscribe, app, stream_key, who})
      {:reply, :ok, server}
    end

    def handle_info({:client_connected, _app, stream_key}, server) do
      Logger.info("Client connected #{stream_key}")
      {:noreply, server}
    end

    defp appname() do
      "feed"
    end

    @stream_salt "laphub_video"
    defp stream_key(sesh) do
      # TODO: encrypt
      token =
        Jason.encode!(%{
          "sesh_id" => sesh.id
        })

      Phoenix.Token.sign(LaphubWeb.Endpoint, @stream_salt, token, max_age: :infinity)
    end

    def decrypt_key(token) do
      case Phoenix.Token.verify(LaphubWeb.Endpoint, @stream_salt, token) do
        {:ok, b} ->
          Jason.decode!(b)

        e ->
          e
      end
    end

    def subscribe(sesh) do
      app = appname()
      stream_key = stream_key(sesh)
      GenServer.call(__MODULE__, {:subscribe, app, stream_key, self()})
    end

    def connect_info(sesh) do
      %{
        url: "rtmp://localhost:#{@port}/#{appname()}",
        key: stream_key(sesh)
      }
    end
  end

  # Init from OBS first
  def init([client_ref, stream_key]) do
    %{"sesh_id" => id} = RTMPServer.decrypt_key(stream_key)
    %Sesh{} = sesh = Laphub.Repo.get(Sesh, id)

    Logger.metadata(sesh_id: sesh.id)
    path = path_to(sesh)
    File.mkdir_p!(path)

    {:ok, _sup, pipeline} =
      Membrane.Pipeline.start_link(Laphub.Video.Pipeline,
        path: path,
        client_ref: client_ref,
        manager: self()
      )

    ref = Process.monitor(pipeline)
    {:ok, %{status: :connected, path: path, socket: {ref, pipeline}}}
  end

  # Init from the browser first
  def init([%Sesh{} = sesh]) do
    Logger.metadata(sesh_id: sesh.id)
    path = path_to(sesh)
    File.mkdir_p!(path)
    VideoServerRegistry.register(sesh)
    RTMPServer.subscribe(sesh)
    Logger.info("Video server is up at #{path}")

    {:ok, %{status: :listening, socket: nil, sesh: sesh, path: path}}
  end

  def handle_info({:client_ref, client_ref, _app, stream_key}, state) do
    {:ok, sup, pipeline} =
      Membrane.Pipeline.start_link(Laphub.Video.Pipeline,
        path: state.path,
        client_ref: client_ref,
        manager: self()
      )

    ref = Process.monitor(pipeline)

    Logger.info(
      "Somebody connected stream_key=#{stream_key} client_ref=#{inspect(client_ref)} pipeline=#{inspect(pipeline)} sup=#{inspect(sup)}"
    )

    {:noreply, emit(%{state | status: :connected, socket: {ref, pipeline}})}
  end

  def handle_info({:DOWN, ref, :process, pipeline, reason}, %{socket: {ref, pipeline}} = state) do
    Logger.info("Video server has shut down: #{inspect(reason)}")
    {:noreply, emit(%{state | status: :listening, socket: nil})}
  end

  def handle_info(:end_of_stream, state) do
    Logger.info("Video stream has ended")
    {:noreply, emit(%{state | status: :listening})}
  end

  def handle_info(other, state) do
    Logger.info("Unhandled #{inspect(other)}")
    {:noreply, state}
  end

  def handle_call(:current, _, state) do
    {:reply, public_state(state), state}
  end

  defp emit(state) do
    publish(state.sesh, public_state(state))
    state
  end

  defp public_state(state) do
    %{status: state.status}
  end

  def path_to(%Sesh{id: id}) do
    "/home/chris/Desktop/laphub_video_output/sesh_#{id}"
  end

  def path_to(%Sesh{} = s, filename) do
    Path.join([path_to(s), filename])
  end

  defp topic(sesh), do: "vid_#{sesh.id}"

  defp publish(sesh, message) do
    IO.inspect({:broadcast, topic(sesh), message})
    PubSub.broadcast(Laphub.InternalPubSub, topic(sesh), {__MODULE__, message})
  end

  def subscribe(sesh) do
    PubSub.subscribe(Laphub.InternalPubSub, topic(sesh))
  end

  def current_state(sesh) do
    case whereis(sesh) do
      nil -> %{status: :unknown}
      pid -> GenServer.call(pid, :current)
    end
  end

  defp whereis(target) do
    Enum.find_value(VideoServerRegistry.all_sesh(), fn {pid, sesh} ->
      if sesh.id == target.id do
        pid
      else
        nil
      end
    end)
  end
end
