defmodule Reading do
  use Ecto.Schema

  schema "readings" do
    field(:timestamp, :integer)
    field(:sensor_type, :string)
    field(:value, :float)
    field(:node_name, :string)
  end
end
