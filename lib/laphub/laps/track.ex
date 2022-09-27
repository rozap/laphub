defmodule Laphub.Laps.Track do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:title, :coords, :inserted_at]}
  schema "tracks" do
    field :coords, {:array, :map}
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(track, attrs) do
    track
    |> cast(attrs, [:title, :coords])
    |> validate_required([:title, :coords])
  end

end
