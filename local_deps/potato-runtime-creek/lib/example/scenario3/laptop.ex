defmodule Laptop do
  @moduledoc """
  Code that represents a sensor in a network. Not deployed with anything but utility software.
  """
  alias Potato.Network.Observables, as: Net
  use Creek
  use Potato.DSL
  alias Creek.Source.Subject, as: Subject
  alias Creek.Source, as: Source

  def init(opts) do
    # Our node descriptor.
    nd = %{
      hardware: :laptop,
      type: :laptop,
      name: "laptop",
      room: "room_3",
      uuid: ?a..?z |> Enum.shuffle() |> Enum.take(5) |> to_string
    }

    Potato.Network.Meta.set_local_nd(nd)
  end

  def run(room) do
    init(room)
    ping_students()
    nil
  end

  #############################################################################
  # Students that are supposed to be here, but are not here.
  defdag missing_students(src, snk, room) do
    src
    ~> filter(fn {event, device} ->
      event in [:join, :update] and
        device.type == :smartphone and
        Map.has_key?(device, :role) and device.role == :student and
        Map.has_key?(device, :next_lecture) and device.next_lecture.room == room and
        Map.has_key?(device, :room) and device.room != room
    end)
    ~> map(fn {_, device} -> device end)
    ~> snk
  end

  #############################################################################
  # Send notification to the students from the laptop.

  defdag query_students(src, snk) do
    src ~> snk
  end

  #############################################################################
  # Capture the reply on the smartphone.

  defdag capture_reply(src, snk) do
    src
    ~> filter(&Kernel.match?({:incoming}, &1))
    ~> map(fn _ -> {:incoming, Potato.Network.Meta.get_local_nd().uuid} end)
    ~> snk
  end

  #############################################################################
  # Gather replies on the laptop.

  defdag gather_responses(src, timer, snk) do
    ((timer ~> debug ~>  take(1)) ||| src)
    ~> zipLatest()
    ~> map(fn {_, {:incoming, uuid}} -> IO.puts("#{uuid} is coming!") end)
    ~> snk
  end

  def ping_students() do
    # Local stream of students that are supposed to be in class.
    students = Creek.Source.gatherer()
    replies = Creek.Source.gatherer()

    # Listen for replies for a minute.
    deploy(gather_responses, src: replies, timer: Creek.Source.delay(10_000), snk: Creek.Sink.ignore(nil))

    # Query the missing students that are supposed to be in class.
    querier =
      Creek.Sink.each(fn student ->
        p = program do
          Creek.Source.Subject.next(Process.whereis(:notifications), "Are you coming to class?")
          deploy(capture_reply, src: Process.whereis(:gui_events), snk: replies)
          nil
        end

        Creek.Source.Subject.next(student.deploy, p)
      end)

    deploy(query_students, src: students, snk: querier)

    # Stream the missing students.
    deploy(missing_students, src: Net.network(), snk: students, room: Potato.Network.Meta.get_local_nd().room)
  end
end
