defmodule Laphub.Repo.Migrations.AddMultiseries do
  use Ecto.Migration

  def change do
    alter table(:lap_sesh) do
      add :series, :jsonb
    end
  end
end
