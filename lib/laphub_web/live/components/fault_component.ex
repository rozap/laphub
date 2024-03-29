defmodule LaphubWeb.Components.FaultComponent do
  use Phoenix.LiveView
  import LaphubWeb.Components.Util

  def mount(_, _, socket) do
    {:ok, assign(socket, :state, :uninit)}
  end

  def handle_event("init", _, socket) do
    {:noreply, assign(socket, :state, :init)}
  end

  def handle_event("test-sound", _, socket) do
    {:noreply, push_event(socket, "fault:test", %{})}
  end

  def render_ok(assigns) do
    ~H"""
      <span>
      Fault status: OK
        <a phx-click="test-sound">
          Test Sound
        </a>
      </span>
    """
  end


  def render(assigns) do
    class = classnames(%{
      "fault" => true,
      "not-init" => assigns.state == :uninit,
      "ok" => assigns.state == :init,
      "error" => assigns.state == :error
    })

    ~H"""
    <div phx-hook="Fault" phx-click="init" class={class} id="fault">
      <%= case @state do
        :init -> render_ok(assigns)
        :uninit -> "Sound is disabled. Click here to enable"
        :error -> "Fault!"
      end %>
    </div>
    """
  end
end
