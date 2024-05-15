defmodule VUB do
  @moduledoc """
  Code that represents a sensor in a network. Not deployed with anything but utility software.
  """
  alias Potato.Network.Observables, as: Net
  require Logger
  use Creek
  use Potato.DSL
  alias Creek.Source.Subject, as: Subject
  alias Creek.Source, as: Source

  def init(opts \\ []) do
    # Our node descriptor.
    nd = %{
      hardware: :update_server,
      type: :update_server,
      name: "update server",
      uuid: ?a..?z |> Enum.shuffle() |> Enum.take(5) |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  #############################################################################
  # Update all devices, if necessary.

  defdag update_phones(src, snk, update, version) do
    src
    ~> filter(fn {event, device} ->
      event == :join and device.type == :smartphone and device.version < version
    end)
    ~> map(fn {:join, phone} ->
      Subject.next(phone.deploy, update)
    end)
    ~> snk
  end

  #############################################################################
  # Average soundlevel on campus.

  defdag update_slms(src, snk, measurements_sink) do
    src
    ~> filter(fn {event, device} ->
      event == :join and device.type == :slm
    end)
    ~> map(fn {_event, device} -> device end)
    ~> map(fn slm ->
      p =
        program do
          # Create stream of measurements.
          measurement_stream =
            Creek.Source.function(fn ->
              m = SoundLeveLMeter.measure()
              Process.sleep(1000)
              m
            end)

          Process.sleep(5000)
          deploy_module(Slm.Streams, :stream_measurements, src: measurement_stream, snk: measurements_sink)
        end

      Subject.next(slm.deploy, p)
    end)
    ~> snk
  end

  #############################################################################
  # Listen on GUI for options.

  defdag process_measurements(src, on, off) do
    src
    ~> average(10)
    ~> average(60)
    ~> map(fn x ->
      IO.inspect("Average: #{x}")
      x
    end)
    ~> dup(2)
    ~> (filter(fn m -> m > 50 end) ~> on ||| filter(fn m -> m <= 50 end) ~> off)
  end

  defdag listen_toggle_event(src, snk) do
    src
    ~> map(fn x ->
      IO.puts("GUI event: #{inspect(x)}")
      x
    end)
    ~> map(fn event ->
      # Gather the average soundlevel.
      measurements_sink = Creek.Source.gatherer()

      on =
        Creek.Sink.each(fn measurement ->
          IO.puts("Closing windows")
          # close_windows()
        end)

      off =
        Creek.Sink.each(fn measurement ->
          IO.puts("Opening windows")
          # open_windows()
        end)

      deploy(process_measurements, src: measurements_sink, on: on, off: off)
      deploy(update_slms, src: Net.network(), snk: Creek.Sink.ignore(nil), measurements_sink: measurements_sink)

      nil
    end)
    ~> snk
  end

  #############################################################################
  # Entry Point

  def run() do
    init([])

    # Deploy an update to all devices.
    update =
      program do
        IO.puts("Patching GUI for additional button.")
        Potato.Network.Meta.set_local_nd_field(:version, "1.0.1")

        # Listen for he GUI event of enabling the windows.
        deploy(listen_toggle_event, src: Process.whereis(:gui_events), snk: Creek.Sink.ignore(nil))
      end

    deploy(update_phones, src: Net.network(), snk: Creek.Sink.ignore(nil), update: update, version: "1.0.1")
    nil
  end
end
