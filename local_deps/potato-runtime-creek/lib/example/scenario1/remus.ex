defmodule Remus do
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
      room: "room_3",
      name: "remus",
      uuid: ?a..?z |> Enum.shuffle() |> Enum.take(5) |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  ##############################################################################
  # Turn off all plugs in current room.

  defdag disable_plugs(src, snk, room) do
    src
    ~> filter(fn {event, device} ->
      self = Potato.Network.Meta.get_local_nd()
      event == :join and device.room == self.room and device.type == :plug
    end)
    ~> map(fn {:join, plug} ->
      p =
        program do
          Plug.turn_off()
        end

      Subject.next(plug.deploy, p)
    end)
    ~> snk
  end

  ##############################################################################
  # Stream the temperature from all thermometers in the room.

  defdag control_hvac(src, snk, limit) do
    src
    ~> map(fn x ->
      IO.puts("HVAC got temperature: #{inspect(x)}")
      x
    end)
    ~> average()
    ~> map(fn t ->
      if t > limit do
        HVAC.turn_on()
      else
        HVAC.turn_off()
      end
    end)
    ~> snk
  end

  defdag update_hvac(src, snk, temp_source, desired) do
    src
    ~> filter(fn {event, device} ->
      self = Potato.Network.Meta.get_local_nd()
      event == :join and device.room == self.room and device.type == :hvac
    end)
    ~> map(fn {:join, hvac} ->
      p =
        program do
          deploy(control_hvac, src: temp_source, snk: Creek.Sink.ignore(nil), limit: desired)
          nil
        end

      Subject.next(hvac.deploy, p)
    end)
    ~> snk
  end

  defdag stream_temp(src, snk) do
    src
    ~> map(fn _ -> Thermostat.read_temperature() end)
    ~> snk
  end

  defdag stream_temp_temp_to_hvac(src, snk, temp_sink) do
    src
    ~> filter(fn {event, device} ->
      self = Potato.Network.Meta.get_local_nd()
      event == :join and device.room == self.room and device.type == :thermostat
    end)
    ~> map(fn {:join, thermometer} ->
      p =
        program do
          deploy(stream_temp, src: Creek.Source.range(1, :inifinity, 0, 1000), snk: temp_sink)
        end

      Subject.next(thermometer.deploy, p)
    end)
    ~> snk
  end

  defdag print_temperature(src, snk) do
    src
    ~> average()
    ~> debug
    ~> snk
  end

  #############################################################################
  # Set ventilation to 20%

  defdag update_ventilation(src, snk, desired) do
    src
    ~> filter(fn {event, device} ->
      self = Potato.Network.Meta.get_local_nd()
      event == :join and device.room == self.room and device.type == :ventilation
    end)
    ~> map(fn {:join, ventilation} ->
      p =
        program do
          Ventilation.set_ventilation(desired)
        end

      Subject.next(ventilation.deploy, p)
    end)
    ~> snk
  end

  #############################################################################
  # Turn off the room computer

  defdag shutdown_computer(src, snk) do
    src
    ~> filter(fn {event, device} ->
      self = Potato.Network.Meta.get_local_nd()
      event == :join and device.room == self.room and device.type == :computer
    end)
    ~> map(fn {:join, computer} ->
      IO.puts("Deploying on computer #{inspect(self())}")

      p =
        program do
          Computer.turn_off()
        end

      Subject.next(computer.deploy, p)
    end)
    ~> snk
  end

  #############################################################################
  # Set the beamer to USB C.

  defdag set_beamer(src, snk, source) do
    src
    ~> filter(fn {event, device} ->
      self = Potato.Network.Meta.get_local_nd()
      event == :join and device.room == self.room and device.type == :beamer
    end)
    ~> map(fn {:join, beamer} ->
      p =
        program do
          Beamer.set_output(source)
        end

      Subject.next(beamer.deploy, p)
    end)
    ~> snk
  end

  #############################################################################
  # Dim lights in rows.
  defdag dim_lights(src, snk, rows, brightness) do
    src
    ~> filter(fn {event, device} ->
      self = Potato.Network.Meta.get_local_nd()
      event == :join and device.room == self.room and device.type == :light and device.row in rows
    end)
    ~> map(fn {:join, light} ->
      p =
        program do
          LightBulb.brightness(brightness)
        end

      Subject.next(light.deploy, p)
    end)
    ~> snk
  end

  #############################################################################
  # Disable internet for students.

  defdag disable_wifi(src, snk, allowed, disallowed) do
    src
    ~> filter(fn {event, device} ->
      self = Potato.Network.Meta.get_local_nd()
      event == :join and device.room == self.room and device.type == :accesspoint
    end)
    ~> map(fn {:join, accesspoint} ->
      p =
        program do
          AccessPoint.filter(allowed, disallowed)
        end

      Subject.next(accesspoint.deploy, p)
    end)
    ~> snk
  end

  #############################################################################
  # Run

  def run() do
    init()

    # When Remus enters, the temperature is set to 20 degrees.
    kill_switch = Creek.Source.gatherer()
    temps = Creek.Source.gatherer()
    deploy(update_hvac, src: Net.network(), snk: kill_switch, temp_source: temps, desired: 20.0)
    deploy(stream_temp_temp_to_hvac, src: Net.network(), snk: kill_switch, temp_sink: temps)

    # Turn off all the plugs.
    deploy(disable_plugs, src: Net.network(), snk: Creek.Sink.ignore(nil))

    # Deploy the hvac stream.

    # Print the temperatures locally for debugging.
    deploy(print_temperature, src: temps, snk: kill_switch)

    # Set the ventilation to 20%.
    # deploy(update_ventilation, src: Net.network(), snk: Creek.Sink.ignore(nil), desired: 20.0)

    # Turn off computer in room, but only do it once.
    deploy(shutdown_computer, src: Net.network(), snk: Creek.Sink.first(nil))

    # Set the beamer to USB C, but only do it once.
    deploy(set_beamer, src: Net.network(), snk: Creek.Sink.first(nil), source: :usb_c)

    # Dim the first three rows of lights.
    deploy(dim_lights, src: Net.network(), snk: Creek.Sink.first(nil), rows: [1, 2, 3])

    # Disable WiFi
    deploy(disable_wifi, src: Net.network(), snk: Creek.Sink.first(nil), allowed: [:teachers], disallowed: [:students])
    nil
  end

  # Simlutes the phone moving around in the building.
  def location_simulator() do
    spawn(fn ->
      for i <- 1..10000 do
        IO.puts("Changing room to room_#{i}")
        Potato.Network.Meta.set_local_nd_field(:room, "room_#{i}")
        Process.sleep(10000)
      end
    end)
  end
end
