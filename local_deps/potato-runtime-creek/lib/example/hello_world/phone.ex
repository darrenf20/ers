defmodule Phone do
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

  defdag print(src, snk) do
    let joins as filter(fn event ->
                   Kernel.match?({:join, _}, event)
                 end)
                 ~> map(fn {:join, device} ->
                   IO.puts("Device joined: #{device.name}")
                 end)

    let leaves as filter(fn event ->
                    Kernel.match?({:part, _}, event)
                  end)
                  ~> map(fn {:part, device} ->
                    IO.puts("Device left: #{device.name}")
                  end)

    src
    ~> dup()
    ~> (joins.() ||| leaves.())
    ~> merge()
    ~> snk
  end

  defdag deploy(src, snk) do
    let deploys as filter(fn event ->
                     Kernel.match?({:join, _}, event)
                   end)
                   ~> map(fn {:join, device} ->
                     p =
                       program do
                         IO.puts("Hello, World!")
                       end

                     Subject.next(device.deploy, p)
                   end)

    src
    ~> deploys.()
    ~> snk
  end

  def run() do
    init()
    snk = Creek.Sink.ignore(nil)
    deploy(print, src: Net.network(), snk: snk)
    deploy(deploy, src: Net.network(), snk: snk)
    nil
  end
end
