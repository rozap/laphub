defmodule LaphubWeb.TelemetryChannel do
  use Phoenix.Channel
  alias Laphub.Repo
  alias Laphub.Laps.{ActiveSesh, Sesh}
  require Logger

  def join("telemetry:" <> id, _message, socket) do
    %Sesh{} = sesh = Repo.get(Sesh, id)

    socket =
      socket
      |> assign(:sesh, sesh)

    {:ok, socket}
  end

  def handle_in("sample", %{"label" => label, "value" => value}, socket) do
    {:ok, pid} = ActiveSesh.get_or_start(socket.assigns.sesh)
    ActiveSesh.publish(pid, label, value)
    {:noreply, socket}
  end

  def handle_in("samples", %{"label" => label, "value" => frame}, socket) do
    {:ok, pid} = ActiveSesh.get_or_start(socket.assigns.sesh)
    ActiveSesh.publish_all(pid, label, unfold_frame(frame))
    {:noreply, socket}
  end

  defp unfold_frame(frame) do
    frame
    |> String.split("|")
    |> Enum.flat_map(fn row ->
      case String.split(row, ":") do
        [offset, value] ->
          [{String.to_integer(offset), String.split(value, ",")}]
        _ ->
          Logger.warn("Malformed frame entry #{row}, skipping")
          []
      end
    end)
  end
end
