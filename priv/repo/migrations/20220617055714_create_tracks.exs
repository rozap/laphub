defmodule Laphub.Repo.Migrations.CreateTracks do
  use Ecto.Migration

  def change do
    create table(:tracks) do
      add :title, :string
      add :coords, {:array, :map}

      timestamps()
    end
  end
end
