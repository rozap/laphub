defmodule Laphub.Laps.Sesh do
  use Ecto.Schema
  import Ecto.Changeset
  alias Laphub.Account.User
  alias Laphub.Laps.{Track, Team}

  defmodule Series do
    use Ecto.Schema

    embedded_schema do
      field :name, :string
      field :type, :string, default: "absolute"
      field :path, :string
    end
  end

  schema "lap_sesh" do
    field :title, :string
    embeds_many :series, Series, on_replace: :delete
    belongs_to :user, User
    belongs_to :track, Track
    belongs_to :team, Team

    timestamps()
  end

  def clear(sesh) do
    changeset(sesh, %{}) |> put_embed(:series, [])
  end

  @doc false
  def changeset(sesh, attrs) do
    sesh
    |> cast(attrs, [:title])
    |> validate_required([])
  end

  def add_series(sesh, key) do
    path =
      Path.join([
        Application.get_env(:laphub, :timeseries_root),
        "sesh_#{sesh.id}",
        UUID.uuid4()
      ])

    new_series = [%Series{name: key, path: path} | sesh.series]

    changeset(sesh, %{})
    |> put_embed(:series, new_series)
  end

  def new(user, track) do
    changeset(
      %__MODULE__{
        user_id: user.id,
        track_id: track.id
      },
      %{}
    )
  end
end
