defmodule Measurements do

  alias Potato.Network.Observables, as: Net
  require Logger
  use Creek
  use Potato.DSL
  alias Creek.Source.Subject, as: Subject
  alias Creek.Source, as: Source
  
  def init_potato() do
    nd = %{
      hardware: :desktop,
      type: :server,
      name: "node_server",
      uuid: ?a..?z |> Enum.shuffle() |> to_string,
    }
    Potato.Network.Meta.set_local_nd(nd)
  end

  # Program to be run on sensor nodes
  defdag stream_vals(src, snk) do
    src
    ~> map(fn _ -> 
      {pin, bus} = Agent.get(:state, & &1)

      {System.os_time(:second), myself().name, [
        {"co2", CO2Sensor.read(bus)},
        {"light", Light.read(bus)},
        {"motion", Motion.read(pin)},
        {"soundLevel", SoundLevel.read()},
        {"temperature", Temperature.read(bus)}
      ]}
    end)
    ~> snk
  end

  # DAG for deploying code to send values to the server
  defdag update(src, snk, val_sink) do            
    src
    ~> filter(fn {event, device} -> event == :join and device.type == :sensor_node end)
    ~> map(fn {:join, node} ->
      p1 = program do
        {:ok, pin} = Circuits.GPIO.open(22, :input)
        {:ok, bus} = Circuits.I2C.open("i2c-1")
        Light.init(bus)
        Agent.start_link(fn -> {pin, bus} end, name: :state)
      end
      
      p2 = program do
        deploy(stream_vals, src: Source.range(0, :infinity, 0, 3000), snk: val_sink)  
      end

      Subject.next(node.deploy, p1)
      Subject.next(node.deploy, p2)
    end)
    ~> snk
  end
  
  # DAG to put values into database
  defdag insert_vals(src, snk) do
    src
    ~> map(fn vs -> insert_data(vs) end)
    ~> snk
  end

  # Inserts a sensor's readings into the database table
  def insert_data(data) do
    case data do
      {time, name, rs} -> Enum.map(rs, fn {s, v} ->
        reading = %Reading{
          timestamp: time,
          sensor_type: s,
          value: v,
          node_name: name
        }

        Repo.insert(reading)
      end)

      err ->
        Logger.error("Received invalid data: #{inspect(err)}")
    end
  end

  def run() do
    HTTP.run()
    
    snk = Creek.Source.gatherer()
    val = Creek.Source.gatherer()
    tml = Creek.Sink.ignore(nil)
    
    deploy(update, src: Net.network(), snk: snk, val_sink: val)
    deploy(insert_vals, src: val, snk: tml)
    
    init_potato()
  end
  
end

