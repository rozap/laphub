defmodule Laphub.Repo.Migrations.AddWidgetStyles do
  use Ecto.Migration

  def change do
    alter table(:dashboards) do
      add :style, :map
    end
  end
end
