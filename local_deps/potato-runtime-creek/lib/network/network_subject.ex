defmodule Creek.Source.NetworkSubject do
  def next(subj, value) do
    send(subj, {:next, value})
  end

  def complete(subj) do
    send(subj, {:complete})
  end

  def source(node, downstreams) do
    source_loop(node, downstreams, [], [], %{})
  end

  def source_loop(node, downstreams, previous, replayed, network) do
    receive do
      ###############
      # Bookkeeping #
      ###############
      {:offer_meta, _, _} ->
        source_loop(node, downstreams, previous, replayed, network)

      {:add_downstream, downstream} ->
        {_, from_gate, _} = downstream
        log("SBJ: Adding downstream #{inspect(downstream)} at gate #{from_gate}")
        source_loop(node, [downstream | downstreams], previous, replayed, network)

      {:delete_downstream, downstream} ->
        err("SBJ: Delete downstream: #{inspect(downstream)}")
        new_downstreams = Enum.filter(downstreams, &(downstream != &1))

        if new_downstreams == [] do
          send_self({:finish})
          warn("SBJ: No downstreams left anymore.")
        else
          warn("OPR: Other downstreams left.")
        end

        source_loop(node, new_downstreams, previous, replayed, network)

      {:finish} ->
        # warn("SBJ: Finished #{node.name}")
        # If a source receives a finish it simply finishes.
        # The finish message *always* comes from the process itself.
        # Itonly has one downstream and that received the complete message.
        :finished

      #################
      # Base Protocol #
      #################
      {:initialize} ->
        log("SBJ: Initializing")

        unreplayed =
          downstreams
          |> Enum.filter(fn ds -> not Enum.member?(replayed, ds) end)

        for value <- Map.values(network) do
          propagate_downstream({:next, {:join, value}}, unreplayed)
        end

        source_loop(node, downstreams, previous, downstreams, network)

      {:next, value} ->
        log("SBJ: Nexting #{inspect(value)}")
        propagate_downstream({:next, value}, downstreams)

        # Update the network.
        network =
          case value do
            {_, nil} ->
              network

            {:join, d} ->
              Map.put(network, d.uuid, d)

            {:part, d} ->
              Map.delete(network, d.uuid)

            _ ->
              network
          end

        source_loop(node, downstreams, [value | previous], replayed, network)

      {:complete} ->
        log("SBJ: Complete!")
        propagate_downstream({:complete}, downstreams)
        send_self({:finish})
        source_loop(node, downstreams, previous, replayed, network)

      m ->
        warn("SBJ: Message not understood: #{inspect(m)}")
    end
  end

  def propagate_downstream(message, downstreams) do
    for {to_pid, from_gate, to_gate} <- downstreams do
      send(to_pid, Tuple.append(message, {self(), from_gate, to_gate}))
    end
  end

  def propagate_upstream(message, upstreams) do
    for {to_pid, from_gate, to_gate} <- upstreams do
      send(to_pid, Tuple.append(message, {self(), from_gate, to_gate}))
    end
  end

  def send_self(message) do
    send(self(), message)
  end

  @log false
  def log(message) do
    if @log do
      IO.puts("#{inspect(self())}: #{message}")
    end
  end

  def warn(message) do
    if true do
      IO.puts(IO.ANSI.yellow() <> "WARN #{inspect(self())}: #{message}" <> IO.ANSI.reset())
    end
  end

  def err(message) do
    if @log do
      IO.puts(IO.ANSI.red() <> "ERR  #{inspect(self())}: #{message}" <> IO.ANSI.reset())
    end
  end
end
