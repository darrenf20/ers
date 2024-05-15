defmodule SingleDeploy do
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
      name: "phone",
      uuid: ?a..?z |> Enum.shuffle() |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  defdag redeploy(src, snk, monitored) do
    let monitor as filter(fn {event, device} ->
                     event == :part and device.uuid == monitored.uuid
                   end)
                   ~> map(fn {:part, device} ->
                     IO.puts("device #{device.uuid} left.")
                     device
                   end)

    let fresh as filter(fn {event, device} ->
                   event == :join and device.uuid != monitored.uuid
                 end)
                 ~> map(fn {:join, device} ->
                   IO.puts("device #{device.uuid} joined")
                   device
                 end)

    src
    ~> dup(2)
    ~> (monitor.() ||| fresh.())
    ~> zip()
    ~> take(1)
    ~> map(fn {_old, new} ->
      deploy(redeploy, src: Net.network(), snk: Creek.Sink.ignore(nil), monitored: new)
      new
    end)
    ~> run_program
    ~> snk
  end

  dag run_program as map(fn device ->
                       p =
                         program do
                           IO.puts("Hello, World!")
                         end

                       Subject.next(device.deploy, p)
                       device
                     end)

  defdag deploy_one(src, snk) do
    src
    ~> filter(fn event ->
      Kernel.match?({:join, _}, event)
    end)
    ~> take(1)
    ~> map(fn {:join, d} -> d end)
    ~> run_program()
    ~> map(fn device ->
      IO.puts("Monitoring #{device.uuid}")
      deploy(redeploy, src: Net.network(), snk: Creek.Sink.ignore(nil), monitored: device)
    end)
    ~> snk
  end

  def run() do
    init()
    snk = Creek.Sink.ignore(nil)
    deploy(deploy_one, src: Net.network(), snk: snk)
    nil
  end
end
