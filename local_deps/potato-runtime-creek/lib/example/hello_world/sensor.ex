defmodule Sensor do
  @moduledoc """
  Code that represents a sensor in a network. Not deployed with anything but utility software.
  """
  alias Potato.Network.Observables, as: Net
  require Logger
  use Creek
  use Potato.DSL
  alias Creek.Source.Subject, as: Subject
  alias Creek.Source, as: Source

  def init() do
    # Our node descriptor.
    nd = %{
      hardware: :android,
      type: :phone,
      name: "sensor",
      uuid: ?a..?z |> Enum.shuffle() |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  def run() do
    init()
  end

  def read_sensor() do
    :rand.uniform_real() * 30
  end
end
