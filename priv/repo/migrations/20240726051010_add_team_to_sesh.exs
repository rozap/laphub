defmodule Laphub.Repo.Migrations.AddTeamToSesh do
  use Ecto.Migration

  def change do
    alter table(:lap_sesh) do
      add :team_id, references(:teams, on_delete: :nothing)
    end

    create table(:teammates) do
      add :team_id, references(:teams, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
    end
  end
end
