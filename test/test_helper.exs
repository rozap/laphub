ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Laphub.Repo, :manual)

defmodule TestHelpers do
  alias Laphub.Laps.ActiveSesh
  alias Laphub.Repo
  alias Laphub.Account.User
  alias Laphub.Laps.{Sesh, Track}
  alias Laphub.Laps.Timeseries

  @start_finish [
    %{lat: 1.5, lng: -1},
    %{lat: 1.5, lng: 1}
  ]

  def create_sesh(start_finish \\ @start_finish) do
    user = %User{email: "test@test.com", display_name: "test"} |> Repo.insert!()
    track = %Track{title: "the ridge", start_finish_line: start_finish} |> Repo.insert!()
    Sesh.new(user, track) |> Repo.insert!()
  end

  def dump_sesh_pubsub() do
    receive do
      {Laphub.Laps.ActiveSesh, msg} ->
        [msg | dump_sesh_pubsub()]
    after
      0 -> []
    end
  end
end
