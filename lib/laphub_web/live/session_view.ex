defmodule LaphubWeb.SessionLive do
  use Phoenix.LiveView
  require Logger
  import Ecto.Query
  alias LaphubWeb.Router.Helpers, as: Router

  alias LaphubWeb.Components.Widget

  alias LaphubWeb.Components.{
    DateRangeComponent,
    ColumnSelector,
    ChartComponent,
    MapComponent,
    LaptimesComponent,
    FaultComponent,
    DriversComponent,
    VideoComponent
  }

  alias Laphub.{Time, Laps, Repo}
  alias Laphub.Laps.{ActiveSesh, Dashboard, Dashboards}

  def mount(%{"session_id" => id} = params, %{"user" => user}, socket) do
    sesh = Laps.my_sesh(user.id, id)

    ActiveSesh.subscribe(sesh)
    {:ok, pid} = ActiveSesh.get_or_start(sesh)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:sesh, sesh)
      |> assign(:pid, pid)
      |> assign(:columns, ActiveSesh.columns(pid))
      |> assign(:dashboard, get_dash(params, user))
      |> assign(:tz, "America/Los_Angeles")

    {:ok, socket}
  end

  defp get_dash(%{"dash_id" => id}, _user) do
    Repo.one(from d in Dashboard, where: d.id == ^id)
  end

  defp get_dash(_, user) do
    Dashboards.get_or_create_default(user)
  end

  def handle_params(params, _, socket) do
    socket =
      socket
      |> assign(:dashboard, get_dash(params, socket.assigns.user))

    {:noreply, socket}
  end

  def handle_event("dnd", %{"new" => new, "old" => old}, socket) do
    Dashboard.reposition(socket.assigns.dashboard, old, new)
    |> Repo.update!()
    |> update_dash

    {:noreply, socket}
  end

  def handle_event("save", _, socket) do
  end


  def handle_info({ActiveSesh, {:append, _key, _dimensions}}, socket) do
    {:noreply, socket}
  end

  def handle_info({:update_dash, dashboard}, socket) do
    dash_url =
      Router.session_path(LaphubWeb.Endpoint, :session, socket.assigns.sesh.id, dashboard.id, %{})

    socket =
      socket
      |> assign(:dashboard, dashboard)
      |> push_patch(to: dash_url, replace: true)

    {:noreply, socket}
  end


  def update_dash(dash) do
    send(self(), {:update_dash, dash})
  end

  # def handle_info({DateRangeComponent, new_range}, socket) do
  #   socket =
  #     socket
  #     |> assign(:range, print_range(new_range))

  #   {:noreply, socket}
  # end

  def render(assigns) do
    ~H"""
    <div class="session">
      <div class="lap-viewer">
      <div class="toolbar">
        <%= live_render(@socket, DateRangeComponent,
          id: "date-range-view",
          session: %{
            "sesh" => @sesh
          }
        ) %>
        <.live_component
          module={ColumnSelector}
          id="column-selector"
          columns={ActiveSesh.columns(@pid)}
          selected={
            Enum.flat_map(@dashboard.widgets, fn w ->
              w.columns
            end)
            |> MapSet.new
          }
          on_add={fn column ->
            Dashboard.add_chart(assigns.dashboard, column)
            |> Repo.update!
            |> update_dash()
          end}
          on_delete={fn column ->
            Dashboard.remove_chart(assigns.dashboard, column)
            |> Repo.update!
            |> update_dash()
          end} />
      </div>



      <div phx-hook="Dnd" id="widgets" class="widgets">
      <%= for w <- @dashboard.widgets do %>
          <div style={Widget.make_style(w)} class="widget-wrap">
            <%
              w_mod = case w.component do
                "fault" -> FaultComponent
                "chart" -> ChartComponent
                "map" -> MapComponent
                "laptimes" -> LaptimesComponent
                "drivers" -> DriversComponent
                "video" -> VideoComponent
              end
              modname = Atom.to_string(w_mod) |> String.split(".") |> List.last() |> to_string() |> String.downcase()
              id = "#{w.title}-#{modname}"
            %>

            <%= live_render @socket, w_mod, id: id, session: %{
              "sesh" => @sesh,
              "widget" => w
            } %>
          </div>
        <% end %>
      </div>

      </div>
    </div>
    """
  end
end
