defmodule Laphub.Laps do
  import Ecto.Query
  alias Laphub.Repo
  alias Laphub.Laps.{Track}
  def tracks() do
    Repo.all(from t in Track)
  end
end
