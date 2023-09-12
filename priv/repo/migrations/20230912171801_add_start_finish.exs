defmodule Laphub.Repo.Migrations.AddStartFinish do
  use Ecto.Migration

  def change do
    alter table(:tracks) do
      add :start_finish_line, {:array, :map}
    end
  end
end
