defmodule ERS.Supervisor do
  use Supervisor
  
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      Repo
    ]

    opts = [strategy: :one_for_one, name: ERS.Supervisor]
    Supervisor.init(children, opts)
  end
end
