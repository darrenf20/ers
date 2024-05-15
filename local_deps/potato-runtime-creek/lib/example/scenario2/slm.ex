defmodule SoundLeveLMeter do
  @moduledoc """
  Code that represents a sensor in a network. Not deployed with anything but utility software.
  """
  require Logger
  use Creek
  use Potato.DSL

  def init(opts) do
    # Our node descriptor.
    nd = %{
      hardware: Keyword.get(opts, :hardware),
      type: Keyword.get(opts, :type),
      name: "slm",
      uuid: ?a..?z |> Enum.shuffle() |> Enum.take(5) |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  def run(brand, type) do
    init(hardware: brand, type: :slm)
  end

  # This function mocks a measurement.
  # We cannot have multiple modules in the same codebase with the same name.
  # We emulate different implementations here.
  def measure() do
    case Potato.Network.Meta.get_local_nd().hardware do
      :typea ->
        {:json, :rand.uniform_real() * 60}

      :typeb ->
        {:xml, :rand.uniform_real() * 60}
      :foo ->
        :rand.uniform_real * 60
      end
  end
end
