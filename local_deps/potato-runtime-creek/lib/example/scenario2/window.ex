
defmodule Window do
  @moduledoc """
  Code that represents a sensor in a network. Not deployed with anything but utility software.
  """
  alias Potato.Network.Observables, as: Net
  require Logger
  use Creek
  use Potato.DSL
  alias Creek.Source.Subject, as: Subject
  alias Creek.Source, as: Source

  def init(opts) do
    # Our node descriptor.
    nd = %{
      hardware: :window,
      type: :window,
      name: "window",
      room: Keyword.get(opts, :room),
      uuid: ?a..?z |> Enum.shuffle() |> Enum.take(5) |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  def run(room) do
    init(room: room)
  end
end
