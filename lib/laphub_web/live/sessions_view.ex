defmodule LaphubWeb.SessionsLive do
  use LaphubWeb, :live_view
  import LaphubWeb.Components.CommonComponents
  alias LaphubWeb.SessionView
  alias Laphub.Laps.Sesh
  alias Laphub.Repo

  def render(assigns) do
    ~H"""
      <div class="sessions container">
        <h2>Create a session</h2>

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
      <div class="sessions container">
        <h2>Previous Sessions</h2>
        <ul>
          <%= for s <- @previous do %>
            <li>
              <%= live_redirect(
                "#{s.track.title} on #{date_string(s.inserted_at)}",
                to: Routes.session_path(LaphubWeb.Endpoint, :session, s.id)
              ) %>
            </li>
          <% end %>
        </ul>

      </div>
    """
  end

  def mount(_params, %{"user" => user}, socket) do
    socket =
      socket
      |> assign(:tracks, Laphub.Laps.tracks())
      |> assign(:selection, nil)
      |> assign(:user, user)
      |> assign(:previous, Laphub.Laps.my_sessions(user.id))

    {:ok, socket}
  end

  def handle_event("select", %{"track" => id}, socket) do
    {id, ""} = Integer.parse(id)
    selection = Enum.find(socket.assigns.tracks, fn t -> t.id == id end)
    {:noreply, assign(socket, :selection, selection)}
  end

  def handle_event("start", %{}, socket) do
    %{selection: track, user: user} = socket.assigns
    sesh = Sesh.new(user, track) |> Repo.insert!()

    socket =
      socket
      |> put_flash(:info, gettext("Your session has been created"))
      |> push_redirect(to: Routes.session_path(socket, SessionView, sesh))

    {:noreply, socket}
  end
end
