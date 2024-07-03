defmodule Laphub.Laps do
  import Ecto.Query
  alias Laphub.{Repo}
  alias Laphub.Laps.{Track, Sesh}
  require Logger

  def tracks() do
    Repo.all(from(t in Track))
  end

  def my_sessions(user_id) do
    Repo.all(
      from(
        s in Sesh,
        inner_join: t in assoc(s, :track),
        where: s.user_id == ^user_id,
        preload: [:track],
        order_by: [desc: s.id]
      )
    )
  end

  def my_sesh(user_id, id) do
    Repo.one(
      from(
        s in Sesh,
        inner_join: t in assoc(s, :track),
        where: s.user_id == ^user_id and s.id == ^id,
        preload: [:track]
      )
    )
  end
end
