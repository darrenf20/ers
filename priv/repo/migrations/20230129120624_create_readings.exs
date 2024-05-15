defmodule Repo.Migrations.CreateReadings do
  use Ecto.Migration

  def change do
    create table(:readings) do
      add :timestamp, :integer
      add :sensor_type, :string
      add :value, :float
      add :node_name, :string
    end
  end
end
