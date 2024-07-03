defmodule Laphub.Repo.Migrations.AddTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :owner_id, references(:users, on_delete: :nothing)
      add :name, :string
      add :description, :text
      add :avatar, :string
      timestamps()
    end
  end
end
