defmodule Potato.Network.Observables do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use GenServer
  import GenServer
  require Logger

  alias Potato.Network.Meta

  def start_link(opts \\ []) do
    start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    Registry.register(Potato.PubSub, :node_descriptors, [])

    # The network observable is for local use. It emits events about network joins and parts.
    o = %Creek.Operator{type: :source, arg: nil, name: "network subject", ref: Creek.Server.gen_sym(), in: 0, out: 1, impl: Creek.Source.NetworkSubject}

    network =
      spawn(fn ->
        Creek.Source.NetworkSubject.source(o, [])
      end)

    # The bluetooth observable is the same as network, but then on the bluetooth scanner.
    bluetooth = Creek.Source.subject()

    # The subject for deployment is listened to locally, and published widely.
    deployment = Creek.Source.subject()

    # The subject which will allow the local runtime to publish values to the network.
    broadcast = Creek.Source.subject()

    state = %{:network => network, :bluetooth => bluetooth, :deployment => deployment, :broadcast => broadcast}
    {:ok, state}
  end

  #
  # ------------------------ API
  #

  def network(), do: call(__MODULE__, :network)

  def bluetooth(), do: call(__MODULE__, :bluetooth)

  def deployment(), do: call(__MODULE__, :deployment)

  def broadcast(), do: call(__MODULE__, :broadcast)

  #
  # ------------------------ Callbacks
  #

  def handle_call({:added, remote, nd}, _from, state) do
    Creek.Source.ReplaySubject.next(state.network, {:join, nd})
    {:reply, :ok, state}
  end

  def handle_call({:updated, remote, nd}, _from, state) do
    Creek.Source.Subject.next(state.network, {:update, nd})
    {:reply, :ok, state}
  end

  def handle_call({:removed, remote, nd}, _from, state) do
    Creek.Source.Subject.next(state.network, {:part, nd})
    {:reply, :ok, state}
  end

  def handle_call(:network, _from, state) do
    {:reply, state.network, state}
  end

  def handle_call(:bluetooth, _from, state) do
    {:reply, state.bluetooth, state}
  end

  def handle_call(:deployment, _from, state) do
    {:reply, state.deployment, state}
  end

  def handle_call(:broadcast, _from, state) do
    {:reply, state.broadcast, state}
  end
end
