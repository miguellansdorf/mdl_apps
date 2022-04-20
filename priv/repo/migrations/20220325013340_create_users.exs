defmodule MdlApps.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :username, :citext, null: false
      add :email, :citext, null: false
      add :confirmed_at, :naive_datetime
      add :password, :string, null: false
      add :avatar, :string

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
  end
end
