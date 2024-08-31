defmodule LaphubWeb.TeamsLive do
  use Phoenix.LiveView
  import LaphubWeb.Components.CommonComponents
  alias LaphubWeb.SessionView
  alias Laphub.Laps.{Sesh, Team}
  alias Laphub.Repo
  import Ecto.Query
  alias LaphubWeb.Router.Helpers, as: Routes

  def mount(_params, %{"user" => user}, socket) do
    socket =
      socket
      |> assign(:user, user)
      |> assign(:teams, Repo.all(from t in Team, order_by: [desc: t.updated_at]))

    {:ok, socket}
  end

  def mount(_params, _no_user, socket) do
    {:ok, push_redirect(socket, to: Routes.login_path(LaphubWeb.Endpoint, :login_form))}
  end

  def render(assigns) do
    ~H"""
      <section class="teams container">
        <div class="section-title">
        <h2>Teams</h2>
        <.link navigate={Routes.team_editor_path(LaphubWeb.Endpoint, :team_editor)}>
          Start a Team
        </.link>

        </div>

        <%= for t <- @teams do %>
          <article>
            <header>
              <h5><%= t.name %></h5>
            </header>
            <%= t.description %>
          </article>
        <% end %>
      </section>
    """
  end
end
