defmodule Ventilation do
  @moduledoc """
  Code that represents a sensor in a network. Not deployed with anything but utility software.
  """
  require Logger
  use Creek
  use Potato.DSL

  def init(opts) do
    # Our node descriptor.
    nd = %{
      hardware: :renson,
      type: :ventilation,
      room: Keyword.get(opts, :room),
      name: "ventilation",
      uuid: ?a..?z |> Enum.shuffle() |> Enum.take(5) |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  def run(room) do
    init(room: room)
  end

  def set_ventilation(percentage) do
    IO.puts("Setting percentage to #{percentage}%.")
  end
end
