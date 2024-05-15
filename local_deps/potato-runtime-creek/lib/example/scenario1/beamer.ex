defmodule Beamer do
  @moduledoc """
  Code that represents a sensor in a network. Not deployed with anything but utility software.
  """
  require Logger
  use Creek
  use Potato.DSL

  def init(opts) do
    # Our node descriptor.
    nd = %{
      hardware: :epson,
      name: "beamer in room 3",
      type: :beamer,
      room: Keyword.get(opts, :room),
      uuid: ?a..?z |> Enum.shuffle() |> Enum.take(5) |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  def run(room) do
    init(room: room)
  end

  def set_output(output) do
    IO.puts("Setting output to #{output}")
  end
end
