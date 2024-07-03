defmodule LaphubWeb.Components.VideoComponent do
  use Phoenix.LiveView
  alias LaphubWeb.Router.Helpers, as: Routes
  import LaphubWeb.Components.Util

  def mount(_, %{"user" => user, "sesh" => sesh, "widget" => widget}, socket) do
    socket =
      socket
      |> assign(:sesh, sesh)
      |> assign(:user, user)

      {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div phx-hook="Video" id="video"  data-root={
          Routes.hls_path(LaphubWeb.Endpoint, :index, @sesh.id, "index.m3u8")
        }>
      <video

        id="player" controls autoplay class="Player"></video>
    </div>
    """
  end
end
