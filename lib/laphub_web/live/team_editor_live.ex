defmodule LaphubWeb.TeamEditorLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  import LaphubWeb.Components.CommonComponents
  alias LaphubWeb.SessionView
  alias Laphub.Laps.{Team}
  alias Laphub.Repo
  alias LaphubWeb.Router.Helpers, as: Routes
  import LaphubWeb.Components.Inputs

  def mount(_params, %{"user" => user = %{id: user_id}} = params, socket) do
    {team, cset} =
      case params do
        %{"team_id" => team_id} ->
          case Repo.get(Team, team_id) do
            %{owner_id: ^user_id} = team ->
              {team, Team.changeset(team, %{})}

            _ ->
              raise LaphubWeb.Exceptions.Forbidden
          end

        %{} ->
          {%Team{}, Team.new(user)}
      end

    socket =
      socket
      |> assign(:user, user)
      |> assign(:teams, [])
      |> assign(:cset, cset)
      |> assign(:team, team)

    {:ok, socket}
  end

  def mount(_params, _no_user, socket) do
    {:ok, push_redirect(socket, to: Routes.login_path(LaphubWeb.Endpoint, :login_form))}
  end

  def handle_event("change", %{"team" => params}, socket) do
    cset = Team.changeset(socket.assigns.team, params) |> Map.put(:action, :insert)
    {:noreply, assign(socket, :cset, cset)}
  end

  def handle_event("submit", _, socket) do
    team = Repo.insert!(socket.assigns.cset)

    socket =
      socket
      |> push_redirect(
        to: Routes.team_editor_path(LaphubWeb.Endpoint, :team_editor, team.id)
      )
      |> put_flash(:success, "Your team has been created")

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <div class="teams container">
        <h2>Team</h2>
        <.flashes {assigns} />
        <.form for={to_form(@cset, as: :team)} :let={f}
          phx-change="change"
          phx-submit="submit">
          <.text form={f} field={:name} />
          <.textarea form={f} field={:description} />
          <button disabled={not @cset.valid?} type="submit">
            Save
          </button>
        </.form>
      </div>
    """
  end
end
