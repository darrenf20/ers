defmodule Collector do

  use Agent
  use Creek
  use Potato.DSL

  def run() do
    nd = %{
      hardware: :rpi,
      type: :sensor_node,
      name: "pi12",
      uuid: ?a..?z |> Enum.shuffle() |> to_string,
    }
    Potato.Network.Meta.set_local_nd(nd)
  end

end

