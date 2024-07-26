defmodule LaphubWeb.Components.VideoComponent do
  use Phoenix.LiveView
  alias Laphub.Video.VideoServer
  alias LaphubWeb.Router.Helpers, as: Routes

  def mount(_, %{"user" => user, "sesh" => sesh, "widget" => widget}, socket) do
    VideoServer.subscribe(sesh)

    socket =
      socket
      |> assign(:sesh, sesh)
      |> assign(:user, user)
      |> assign(:widget, widget)
      |> assign(:stream_state, VideoServer.current_state(sesh))

    {:ok, socket}
  end

  def handle_info({VideoServer, stream_state}, socket) do
    {:noreply, assign(socket, :stream_state, stream_state)}
  end


  def render(assigns) do
    ~H"""
    <div phx-hook="Video" id="video"  data-root={
          Routes.hls_path(LaphubWeb.Endpoint, :index, @sesh.id, "index.m3u8")
        }>

      <div>
        <% connect = VideoServer.RTMPServer.connect_info(@sesh) %>
        Stream URL <pre><%= connect.url %></pre>
        Stream Key <pre><%= connect.key %></pre>
        Stream State <%= @stream_state.status %>
      </div>

      <video

        id="player" controls autoplay class="Player"></video>
    </div>
    """
  end
end
