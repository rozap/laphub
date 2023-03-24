defmodule LaphubWeb.Components.TrackAddictComponent do
  use Phoenix.LiveComponent
  use Phoenix.HTML
  import LaphubWeb.Components.Util
  import LaphubWeb.Components.CommonComponents
  alias Laphub.Integrations.TrackAddictLive

  def mount(socket) do
    socket =
      socket
      |> assign(:client_pid, nil)
      |> assign(:client_id, "131355221")
    {:ok, socket}
  end

  def handle_event("settings:client_id", %{"value" => value}, socket) do
    {:noreply, assign(socket, :client_id, value)}
  end


  def handle_event("settings:start_client", _, socket) do
    {:ok, pid} = TrackAddictLive.start_link(socket.assigns.client_id, socket.assigns.sesh)
    socket = assign(socket, :client_pid, pid)
    IO.inspect {:wut, pid}
    {:noreply, socket}
  end

  def render_input(assigns) do
    ~H"""
    <div>
      <%= label(:client_id, :client_id, "Track Addict Client ID") %>
      <%= text_input :client_id, :client_id, value: "131355221", phx_keyup: "settings:client_id", phx_target: @myself %>
      <.primary_button
        label="Start"
        myself={@myself}
        click="settings:start_client" />
    </div>

    """
  end

  def render(assigns) do
    class = classnames(%{
      "track-addict" => true,
      "not-init" => assigns.client_pid == nil,
      "ok" => assigns.client_pid && Process.alive?(assigns.client_pid)
    })

    ~H"""
    <div class={class}>
      <%= if    assigns.client_pid do %>
        Running...
      <% else %>
        <%= render_input(assigns) %>
      <% end %>
    </div>
    """
  end
end

