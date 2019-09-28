defmodule Hello.Repo.Migrations.CreateReps do
  use Ecto.Migration

  def change do
    create table(:reps) do
      add :name, :string
      add :desc, :string
      add :stars, :integer
      add :days, :integer
      add :url, :string
      add :real_url, :string
      add :fork, :integer
      add :watch, :integer
      add :grp_name, :string
      add :grp_desc, :string

      timestamps()
    end

  end
end
