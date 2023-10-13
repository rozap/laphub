defmodule LaphubWeb.SessionLive do
  use LaphubWeb, :live_view
  import LaphubWeb.Components.CommonComponents
  require Logger

  alias LaphubWeb.Components.{
    DateRangeComponent,
    ColumnSelector,
    ChartComponent,
    MapComponent,
    LaptimesComponent,
    FaultComponent,
    TrackAddictComponent,
    DriversComponent
  }

  alias Laphub.Laps.Track
  alias Laphub.{Time, Laps, Repo}
  alias Laphub.Laps.{ActiveSesh, Sesh, Dashboard}
  alias Laphub.Laps.Timeseries

  def mount(%{"session_id" => id}, %{"user" => user}, socket) do
    sesh = Laps.my_sesh(user.id, id)

    ActiveSesh.subscribe(sesh)
    {:ok, pid} = ActiveSesh.get_or_start(sesh)

    socket =
      socket
      |> assign(:sesh, sesh)
      |> assign(:pid, pid)
      |> assign(:columns, ActiveSesh.columns(pid))
      |> assign(:dashboard, Dashboard.default())
      |> assign(:tz, "America/Los_Angeles")

    {:ok, socket}
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
      <div class="column-selector">
        <.live_component
          module={ColumnSelector}
          id="column-selector"
          columns={@columns}
          selected_columns={MapSet.new(@columns)}
        />
      </div>

      <div class="lap-viewer">
      <div class="toolbar">
        <%= live_render(@socket, DateRangeComponent,
          id: "date-range-view",
          session: %{
            "sesh" => @sesh
          }
        ) %>
      </div>

        <%= for w <- @dashboard.widgets do %>
          <div>
            <%
              w_mod = case w.component do
                "fault" -> FaultComponent
                "chart" -> ChartComponent
                "map" -> MapComponent
                "laptimes" -> LaptimesComponent
                "drivers" -> DriversComponent
              end
              id = "#{w.title}-#{w_mod}"
            %>

            <%= live_render @socket, w_mod, id: id, session: %{
              "sesh" => @sesh,
              "widget" => w
            } %>
          </div>
        <% end %>


      </div>
    </div>
    """
  end
end
