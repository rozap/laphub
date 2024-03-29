defmodule LapsTest do
  use Laphub.DataCase
  alias Laphub.Laps.ActiveSesh
  alias Laphub.Repo
  alias Laphub.Account.User
  alias Laphub.Laps.{Sesh, Track}
  alias Laphub.Laps.Timeseries
  import TestHelpers

  test "can subscribe to the sesh" do
    sesh = create_sesh()

    {:ok, pid} = ActiveSesh.get_or_start(sesh)

    ActiveSesh.subscribe(sesh)

    ActiveSesh.publish(pid, "voltage", 12.4)
    ActiveSesh.publish(pid, "voltage", 13.4)
    ActiveSesh.publish(pid, "voltage", 13.2)

    assert ["voltage"] == ActiveSesh.columns(pid)

    assert [
             {:append, _, %{"voltage" => 12.4}},
             {:append, _, %{"voltage" => 13.4}},
             {:append, _, %{"voltage" => 13.2}}
           ] = dump_sesh_pubsub()
  end

  test "can stream the values out" do
    sesh = create_sesh()

    {:ok, pid} = ActiveSesh.get_or_start(sesh)

    ActiveSesh.subscribe(sesh)

    ActiveSesh.publish(pid, "voltage", 12.4)
    :timer.sleep(1)
    ActiveSesh.publish(pid, "voltage", 13.4)
    :timer.sleep(1)
    ActiveSesh.publish(pid, "voltage", 13.2)

    assert ["voltage"] == ActiveSesh.columns(pid)

    assert [
             {_, 12.4},
             {_, 13.4},
             {_, 13.2}
           ] =
             ActiveSesh.stream(pid, "voltage", fn kv ->
               Timeseries.all(kv)
             end)
             |> Enum.into([])
  end

  test "can publish a multi value frame" do
    sesh = create_sesh()

    {:ok, pid} = ActiveSesh.get_or_start(sesh)

    ActiveSesh.subscribe(sesh)

    ActiveSesh.publish_all(pid, "voltage", [
      {0, 12.4},
      {100, 13.4},
      {200, 13.1},
      {300, 14.1}
    ])

    assert ["voltage"] == ActiveSesh.columns(pid)

    assert [
             {:append, _, %{"voltage" => 12.4}},
             {:append, _, %{"voltage" => 13.4}},
             {:append, _, %{"voltage" => 13.1}},
             {:append, _, %{"voltage" => 14.1}}
           ] = dump_sesh_pubsub()

    assert [
             {_, 12.4},
             {_, 13.4},
             {_, 13.1},
             {_, 14.1}
           ] =
             ActiveSesh.stream(pid, "voltage", fn kv ->
               Timeseries.all(kv)
             end)
             |> Enum.into([])
  end

  describe "exploding gps events" do
    test "can explode special events" do
      sesh =
        create_sesh([
          %{lat: -1, lng: 0},
          %{lat: 1, lng: 0}
        ])

      {:ok, pid} = ActiveSesh.get_or_start(sesh)

      lap = [
        [0, -1],
        # TODO: it will double count if it's right on the line...
        [0, 0.1],
        [0, 1],
        [1, 1],
        [2, 1],
        [2, 2],
        [2, 1],
        [2, 0],
        [2, -1],
        [1, -1]
      ]

      ActiveSesh.subscribe(sesh)

      lap_count = 1

      Enum.each(0..lap_count, fn l ->
        Enum.each(Range.new(0, length(lap) - 1), fn i ->
          [y, x] = Enum.at(lap, i)
          ActiveSesh.publish(pid, "gps", [to_string(y), to_string(x)])
        end)
      end)

      assert ["gps", "lap"] == ActiveSesh.columns(pid)

      laps =
        dump_sesh_pubsub()
        |> Enum.filter(fn
          {:append, _t, %{"lap" => _}} -> true
          _ -> false
        end)
        |> Enum.map(fn {:append, _t, %{"lap" => lap}} -> lap end)

      assert laps = [0, 1]
    end
  end
end
