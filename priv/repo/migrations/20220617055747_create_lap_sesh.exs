defmodule Laphub.Repo.Migrations.CreateLapSesh do
  use Ecto.Migration

  def change do
    create table(:lap_sesh) do
      add :title, :string
      add :track_id, references(:tracks, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:lap_sesh, [:track_id])
    create index(:lap_sesh, [:user_id])
  end
end
