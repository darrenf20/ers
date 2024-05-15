defmodule Thermostat do
  @moduledoc """
  Code that represents a sensor in a network. Not deployed with anything but utility software.
  """
  require Logger
  use Creek
  use Potato.DSL

  def init(opts) do
    # Our node descriptor.
    nd = %{
      hardware: :google,
      type: :thermostat,
      name: "thermostat",
      room: Keyword.get(opts, :room),
      uuid: ?a..?z |> Enum.shuffle() |> Enum.take(5) |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  def run(room) do
    init(room: room)
  end

  def read_temperature() do
    IO.puts("Reading")
    :rand.uniform_real() * 30
  end
end
