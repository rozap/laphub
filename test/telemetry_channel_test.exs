defmodule TelemetryChannelTest do
  use LaphubWeb.ChannelCase
  import TestHelpers
  alias Laphub.Laps.ActiveSesh

  setup do
    sesh = create_sesh()

    {:ok, _, socket} =
      LaphubWeb.UserSocket
      |> socket("", %{})
      |> subscribe_and_join(LaphubWeb.TelemetryChannel, "telemetry:#{sesh.id}")

    %{socket: socket, sesh: sesh}
  end

  test "can publish single values", %{socket: socket, sesh: sesh} do
    ActiveSesh.subscribe(sesh)
    push(socket, "sample", %{"label" => "voltage", "value" => 13.7})
    push(socket, "sample", %{"label" => "rpm", "value" => 3000})
    push(socket, "sample", %{"label" => "voltage", "value" => 14.2})

    # everything is async, so this is a hack...
    :timer.sleep(10)

    {:ok, pid} = ActiveSesh.get_or_start(sesh)
    cols = ActiveSesh.columns(pid)
    assert cols == ["rpm", "voltage"]

    assert [
             {:append, _, %{"voltage" => 13.7}},
             {:append, _, %{"rpm" => 3000}},
             {:append, _, %{"voltage" => 14.2}}
           ] = dump_sesh_pubsub()
  end

  test "can publish multi values", %{socket: socket, sesh: sesh} do
    ActiveSesh.subscribe(sesh)

    push(socket, "samples", %{
      "label" => "gps",
      "value" => "0:46.964294,-122.734630|100:46.964295,-122.734631|200:46.964297,-122.734633"
    })

    # everything is async, so this is a hack...
    :timer.sleep(10)

    {:ok, pid} = ActiveSesh.get_or_start(sesh)
    cols = ActiveSesh.columns(pid)
    assert cols == ["gps"]

    assert [
      {:append, _, %{"gps" => %{lat: 46.964294, lng: -122.734630}}},
      {:append, _, %{"gps" => %{lat: 46.964295, lng: -122.734631}}},
      {:append, _, %{"gps" => %{lat: 46.964297, lng: -122.734633}}}
    ] = dump_sesh_pubsub()
  end

  test "malformed datum in a frame is skipping", %{socket: socket, sesh: sesh} do
    ActiveSesh.subscribe(sesh)

    push(socket, "samples", %{
      "label" => "gps",
      "value" => "46.964294,-122.734630|100:46.964295,-122.734631|200:46.964297,-122.734633"
    })

    # everything is async, so this is a hack...
    :timer.sleep(10)

    {:ok, pid} = ActiveSesh.get_or_start(sesh)
    cols = ActiveSesh.columns(pid)
    assert cols == ["gps"]

    assert [
      {:append, _, %{"gps" => %{lat: 46.964295, lng: -122.734631}}},
      {:append, _, %{"gps" => %{lat: 46.964297, lng: -122.734633}}}
    ] = (dump_sesh_pubsub())
  end
end
