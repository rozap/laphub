defmodule Laphub.Repo.Migrations.AddTimeseries do
  use Ecto.Migration

  def change do
    alter table(:lap_sesh) do
      add :timeseries, :text
    end
  end
end
