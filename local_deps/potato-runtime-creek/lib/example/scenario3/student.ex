defmodule Student do
  @moduledoc """
  Code that represents a sensor in a network. Not deployed with anything but utility software.
  """
  require Logger
  use Creek
  use Potato.DSL

  def init(opts) do
    # Our node descriptor.
    nd = %{
      hardware: :smartphone,
      type: :smartphone,
      name: "smartphone",
      role: :student,
      room: nil,
      uuid: ?a..?z |> Enum.shuffle() |> Enum.take(5) |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  def run() do
    init([])

    gui_events = Creek.Source.subject(name: :gui_events)
    push_notifications = Creek.Source.subject(name: :notifications)
    nil
  end

end
