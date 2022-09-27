defmodule Laphub.Laps.Sesh do
  use Ecto.Schema
  import Ecto.Changeset
  alias Laphub.Laps.Track

  schema "lap_sesh" do
    field :title, :string
    field :user_id, :id

    field :timeseries, :string
    belongs_to :track, Track

    timestamps()
  end

  @doc false
  def changeset(sesh, attrs) do
    sesh
    |> cast(attrs, [:title])
    |> validate_required([])
  end

  def new(user, track) do
    path =
      Path.join(
        Application.get_env(:laphub, :timeseries_root),
        UUID.uuid4()
      )

    changeset(
      %__MODULE__{
        user_id: user.id,
        track_id: track.id,
        timeseries: path
      },
      %{}
    )
  end
end
