defmodule SmartPhone do
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
      hardware: :android,
      type: :smartphone,
      name: "android phone of Boole",
      version: "1.0.0",
      uuid: ?a..?z |> Enum.shuffle() |> Enum.take(5) |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  def run() do
    init([])

    # Source that emulates events from a GUI.
    gui_events = Creek.Source.subject()
    Process.register(gui_events, :gui_events)
  end

  #############################################################################
  # DAG for average sound level.

  defdag average_soundlevel(src, snk, measurements) do
    src
    ~> filter(fn {event, device} ->
      event == :join and device.name == "slm"
    end)
    ~> map(fn {:join, slm} ->
      p =
        program do
          src =
            Creek.Source.function(fn ->
              res = SoundLeveLMeter.measure()
              Process.sleep(1000)
              res
            end)

          deploy_module(Slm.Streams, :stream_measurements, src: src, snk: measurements)
        end

      Subject.next(slm.deploy, p)
      nil
    end)
    ~> snk
  end

  def enable_option() do
    # Deploy a DAG to compute the average sound level at the campus.
    m = Creek.Sink.each(fn x -> IO.inspect(x) end)
    deploy(average_soundlevel, src: Net.network(), snk: Creek.Sink.ignore(nil), measurements: m)
  end
end
