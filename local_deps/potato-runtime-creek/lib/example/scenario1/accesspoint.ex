defmodule AccessPoint do
  @moduledoc """
  Code that represents a sensor in a network. Not deployed with anything but utility software.
  """
  require Logger
  use Creek
  use Potato.DSL

  def init(opts) do
    # Our node descriptor.
    nd = %{
      hardware: :unifi,
      type: :accesspoint,
      name: "access point in room #{Keyword.get(opts, :room)}",
      room: Keyword.get(opts, :room),
      uuid: ?a..?z |> Enum.shuffle() |> Enum.take(5) |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  def run(room) do
    init(room: room)
  end

  def filter(allowed, disallowed) do
    for a <- allowed do
      IO.puts("Allowing #{a}")
    end

    for d <- disallowed do
      IO.puts("Disallowing #{d}")
    end
  end
end
