defmodule LaphubWeb.Components.ColumnSelectorComponent do
  use Phoenix.LiveComponent
  import LaphubWeb.Components.Util

  def handle_event("toggle", %{"column" => column}, socket) do
    selected = socket.assigns.selected_columns

    selected =
      if MapSet.member?(selected, column) do
        MapSet.delete(selected, column)
      else
        MapSet.put(selected, column)
      end

    {:noreply, assign(socket, :selected_columns, selected)}
  end

  def render(assigns) do
    ~H"""
    <div class="column-selector">
      <ul>
        <%= for c <- @columns do %>
          <%
            attributes = %{
              "class" => classnames(%{
                badge: true,
                primary: MapSet.member?(@selected_columns, c)
                })
              }
          %>
          <li>
            <a phx-target={@myself}
              phx-click="toggle"
              phx-value-column={c} {attributes}>
              <%= c %>
            </a>
          </li>
        <% end %>

      </ul>
    </div>
    """
  end
end
