defmodule LaphubWeb.Components.ColumnSelector do
  use Phoenix.LiveComponent
  import LaphubWeb.Components.Util
  alias LaphubWeb.Components.Modal

  def handle_event("toggle", %{"column" => column}, socket) do
    selected = MapSet.new(socket.assigns.columns)

    selected =
      if MapSet.member?(socket.assigns.selected, column) do
        apply(socket.assigns.on_delete, [column])
      else
        apply(socket.assigns.on_add, [column])
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.live_component module={Modal}
      button="Columns"
      title="Add Series"
      id="column-modal"
      >
        <div class="column-selector">
          <%= for c <- @columns do %>
            <%
            selected =  Enum.member?(@selected, c)
              attributes = %{
                "class" => classnames(%{
                  badge: true,
                  primary: selected
                  })
                }
            %>
              <label for={c}>
                <%= c %>
                <input role="switch" checked={selected} name={c} phx-value-column={c} phx-target={@myself} phx-click="toggle" type="checkbox" />
              </label>
          <% end %>
        </div>
      </.live_component>
    </div>
    """
  end
end
