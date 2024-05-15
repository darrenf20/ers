defmodule Potato.Network.Evaluator do
  @moduledoc """
  The Reactor is the key evaluator on each node.
  Whenever code is sent th
  """
  use GenServer
  require Logger
  import GenServer
  use Creek

  def start_link() do
    start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  defdag evaluator(programs, sink) do
    programs
    ~> map(fn prog ->
      deploy_program(prog)
    end)
    ~> sink
  end

  def init([]) do
    deployment_subject = Potato.Network.Observables.deployment()

    sink = Creek.Sink.ignore(nil)
    deploy(evaluator, programs: deployment_subject, sink: sink)
    {:ok, %{}}
  end

  #
  # ------------------------ API
  #

  @doc """
  Deploys a program locally in the reactor.
  """
  def deploy_program(program), do: cast(__MODULE__, {:deploy_program, program})

  #
  # ------------------------ Callbacks
  #

  def handle_cast({:deploy_program, program}, state) do
    res = program.()

    Logger.debug("""
    Program evaluated
    ======================================
    Result of evaluation: #{inspect(res)}
    ======================================
    """)

    {:noreply, state}
  end
end
