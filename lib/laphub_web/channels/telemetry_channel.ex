defmodule LaphubWeb.TelemetryChannel do
  use Phoenix.Channel
  alias Laphub.Repo
  alias Laphub.Laps.{ActiveSesh, Sesh}

  def join("telemetry:" <> id, message, socket) do
    %Sesh{} = sesh = Repo.get(Sesh, id)

    socket =
      socket
      |> assign(:sesh, sesh)

    {:ok, socket}
  end

  def handle_in("sample", message, socket) do
    {:ok, pid} = ActiveSesh.get_or_start(socket.assigns.sesh)
    ActiveSesh.publish(pid, message)
    {:noreply, socket}
  end
end
