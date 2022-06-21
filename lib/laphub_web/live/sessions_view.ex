defmodule LaphubWeb.SessionsView do
  use LaphubWeb, :live_view
  alias LaphubWeb.LapView

  def render(assigns) do
    ~H"""
      <div class="sessions container">
        <h1>Create a session</h1>

        <div class="track-select">
          <ul>
            <%= for t <- @tracks do %>
              <li>
                <a phx-click="select" phx-value-track={t.id}>
                  <%= t.title %>
                </a>
              </li>
            <% end %>
          </ul>
        </div>
        <div class="selection-view">
          <%= if @selection do %>
            <%= @selection.title %>
            <button phx-click="start">
              Start
            </button>
          <% end %>
        </div>
      </div>
    """
  end

  def mount(_params, %{}, socket) do
    socket =
        socket
        |> assign(:tracks, Laphub.Laps.tracks())
        |> assign(:selection, nil)
    {:ok, socket}
  end

  def handle_event("select", %{"track" => id}, socket) do
    {id, ""} = Integer.parse(id)
    selection = Enum.find(socket.assigns.tracks, fn t -> t.id == id end)
    {:noreply, assign(socket, :selection, selection)}
  end

  def handle_event("start", %{}, socket) do
    session_id = "meh"
    socket =
      socket
      |> put_flash(:info, gettext("Your session has been created"))
      |> push_redirect(to: Routes.live_path(socket, LapView, session_id))

    {:noreply, socket}
  end

end
