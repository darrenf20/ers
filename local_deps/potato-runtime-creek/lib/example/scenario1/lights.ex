defmodule LightBulb do
  @moduledoc """
  Code that represents a sensor in a network. Not deployed with anything but utility software.
  """
  require Logger
  use Creek
  use Potato.DSL

  def init(opts) do
    # Our node descriptor.
    nd = %{
      hardware: :philips,
      type: :light,
      row: Keyword.get(opts, :row),
      name: "light in room #{Keyword.get(opts, :room)}",
      room: Keyword.get(opts, :room),
      uuid: ?a..?z |> Enum.shuffle() |> Enum.take(5) |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  def run(room, row) do
    init(room: room, row: row)
  end

  def brightness(brightness) do
    IO.puts("Setting brightness to #{brightness}%")
  end
end
