defmodule GatedDag.Vertex do
  @type t :: %GatedDag.Vertex{payload: any()}
  alias __MODULE__
  defstruct payload: nil

  @spec new(any) :: GatedDag.Vertex.t()
  def new(payload) do
    %Vertex{payload: payload}
  end

  @spec is_vertex?(any) :: boolean
  def is_vertex?(x) do
    match?(%Vertex{}, x)
  end
end

defmodule GatedDag.InputGate do
  @type t :: %GatedDag.InputGate{index: integer(), belongs_to: GatedDag.Vertex.t()}
  alias __MODULE__
  defstruct index: nil, belongs_to: nil

  @spec new(non_neg_integer(), GatedDag.Vertex.t()) :: GatedDag.InputGate.t()
  def new(index, owner) do
    %InputGate{index: index, belongs_to: owner}
  end

  @spec is_inputgate?(any) :: boolean
  def is_inputgate?(x) do
    match?(%InputGate{}, x)
  end
end

defmodule GatedDag.OutputGate do
  @type t :: %GatedDag.OutputGate{index: integer(), belongs_to: GatedDag.Vertex.t()}
  alias __MODULE__
  defstruct index: nil, belongs_to: nil

  @spec new(non_neg_integer(), GatedDag.Vertex.t()) :: GatedDag.OutputGate.t()
  def new(index, owner) do
    %OutputGate{index: index, belongs_to: owner}
  end

  @spec is_outputgate?(any) :: boolean
  def is_outputgate?(x) do
    match?(%OutputGate{}, x)
  end
end

defmodule GatedDag do
  @type t :: %GatedDag{
          internal: MutableGraph.t(),
          vertices: MapSet.t(),
          edges_from: %{},
          edges_to: %{}
        }
  alias GatedDag.{Vertex, InputGate, OutputGate}

  defstruct internal: MutableGraph.new(), vertices: MapSet.new(), edges_from: %{}, edges_to: %{}

  @spec breadth_first_reduce(GatedDag.t(), (any, any -> any), any) :: :ok
  def breadth_first_reduce(gdag, proc, acc) do
    sources = GatedDag.vertices(gdag) |> Enum.filter(fn v -> vertices_to(gdag, v) == [] end)

    walker(gdag, proc, MapSet.new(), sources, acc)
  end

  defp walker(_, _, _, [], acc) do
    acc
  end

  defp walker(dag, proc, seen, [k | kont], acc) do
    if MapSet.member?(seen, k) do
      walker(dag, proc, seen, kont, acc)
    else
      acc = proc.(k, acc)
      todo = GatedDag.vertices_from(dag, k)
      walker(dag, proc, MapSet.put(seen, k), kont ++ todo, acc)
    end
  end

  @spec new :: GatedDag.t()
  @doc """
  Creates a new gated DAG.
  """
  def new() do
    %GatedDag{}
  end

  @spec del_vertex(GatedDag.t(), any) :: GatedDag.t()
  @doc """
  For a given payload, removes the vertex and its associated in- and output gates.
  """
  def del_vertex(gdag, payload) do
    %GatedDag{internal: idag, vertices: vs, edges_from: ef, edges_to: et} = gdag
    # Create the vertex for the gated dag.
    vertex = Vertex.new(payload)

    input_gates = input_gates_for(gdag, payload)
    output_gates = output_gates_for(gdag, payload)

    # Delete the vertex
    idag =
      idag
      |> MutableGraph.del_vertex(vertex)

    # Delete input gates
    idag =
      input_gates
      |> Enum.reduce(idag, fn igate, idag -> MutableGraph.del_vertex(idag, igate) end)

    # Delete output gates
    idag =
      output_gates
      |> Enum.reduce(idag, fn ogate, idag -> MutableGraph.del_vertex(idag, ogate) end)

    # Delete from payloadset.
    vs = MapSet.delete(vs, payload)

    et =
      Enum.reduce(et, %{}, fn {v, edges}, et ->
        if v == payload do
          et
        else
          edges =
            Enum.filter(edges, fn {f, _fi, t, _ti} ->
              f != payload and t != payload
            end)
            |> MapSet.new()

          Map.put(et, v, edges)
        end
      end)

    ef =
      Enum.reduce(ef, %{}, fn {v, edges}, ef ->
        if v == payload do
          ef
        else
          edges =
            Enum.filter(edges, fn {f, _fi, t, _ti} ->
              f != payload and t != payload
            end)
            |> MapSet.new()

          Map.put(ef, v, edges)
        end
      end)

    %GatedDag{internal: idag, vertices: vs, edges_to: et, edges_from: ef}
  end

  @doc """
  Returns all the payload in this DAG ignoring the gates.
  """
  def vertices(gdag) do
    %GatedDag{vertices: vs} = gdag
    Enum.to_list(vs)

    # idag
    # |> MutableGraph.vertices()
    # |> Enum.filter(&Vertex.is_vertex?/1)
    # |> Enum.map(fn %GatedDag.Vertex{payload: p} -> p end)
  end

  @spec add_vertex(GatedDag.t(), any, integer(), integer()) :: GatedDag.t()
  @doc """
  Adds a new vertex to this gated DAG with `ins` input gates and `outs` output gates.

  We assume that vertex will be unique in the e
  """
  def add_vertex(gdag, payload, ins, outs) do
    %GatedDag{internal: idag, vertices: vs, edges_from: ef, edges_to: et} = gdag

    # Create the vertex for the gated dag.
    vertex = Vertex.new(payload)

    # Create the input and output gates.
    in_gates = if ins > 0, do: Enum.map(0..(ins - 1), &InputGate.new(&1, vertex)), else: []
    out_gates = if outs > 0, do: Enum.map(0..(outs - 1), &OutputGate.new(&1, vertex)), else: []

    # Add the input and output gates to the internal DAG.
    idag =
      idag
      |> MutableGraph.add_vertex(vertex)

    idag =
      Enum.reduce(in_gates, idag, fn ingate, idag ->
        MutableGraph.add_edge(idag, ingate, vertex)
      end)

    idag =
      Enum.reduce(out_gates, idag, fn outgate, idag ->
        MutableGraph.add_edge(idag, vertex, outgate)
      end)

    vs = MapSet.put(vs, payload)

    ef = Map.put(ef, payload, MapSet.new())
    et = Map.put(et, payload, MapSet.new())
    %GatedDag{internal: idag, vertices: vs, edges_to: et, edges_from: ef}
  end

  @spec add_edge(GatedDag.t(), any, non_neg_integer, any, non_neg_integer) :: GatedDag.t()
  @doc """
  Adds an edge going from `from` to `to` with their respective indices.

  Raises if the gate does not exist.
  """
  def add_edge(gdag, from, from_idx, to, to_idx) do
    %GatedDag{internal: idag, edges_to: et, edges_from: ef} = gdag

    # Get the gates for both vertices.
    from_gate = get_output_gate(gdag, from, from_idx)
    to_gate = get_input_gate(gdag, to, to_idx)

    idag =
      idag
      |> MutableGraph.add_edge(from_gate, to_gate)

    # Store the edge in cache.
    the_edge = {from, from_idx, to, to_idx}
    ef = Map.update(ef, from, MapSet.new([the_edge]), &MapSet.put(&1, the_edge))
    et = Map.update(et, to, MapSet.new([the_edge]), &MapSet.put(&1, the_edge))

    %{gdag | internal: idag, edges_from: ef, edges_to: et}
  end

  @spec input_gates_for(GatedDag.t(), any) :: [InputGate.t()]
  @doc """
  For a given payload, returns the list of input gates that exist for that payload in the dag.
  """
  def input_gates_for(gdag, payload) do
    %GatedDag{internal: idag} = gdag

    # Create the vertex for the gated dag.
    vertex = Vertex.new(payload)

    MutableGraph.vertices_to(idag, vertex)
  end

  @spec output_gates_for(GatedDag.t(), any) :: [OutputGate.t()]
  @doc """
  For a given payload, returns the list of output gates that exist for that payload in the dag.
  """
  def output_gates_for(gdag, payload) do
    %GatedDag{internal: idag} = gdag

    # Create the vertex for the gated dag.
    vertex = Vertex.new(payload)

    MutableGraph.vertices_from(idag, vertex)
  end

  @spec indegree(GatedDag.t(), any) :: non_neg_integer
  @doc """
  Returns the amount of connected edges to a vertex.
  If a vertex has `n` input gates, and none of them have an output gate connected to them the total indegree is 0.
  """
  def indegree(gdag, payload) do
    input_gates_for(gdag, payload) |> Enum.count()
  end

  @spec outdegree(GatedDag.t(), any) :: non_neg_integer
  @doc """
  Returns the amount of connected edgs to a vertex.
  If  a vertex has `n` output gates, and none of them have an input gate connected to them the total outdegree is 0.
  """
  def outdegree(gdag, payload) do
    output_gates_for(gdag, payload) |> Enum.count()
  end

  @spec get_input_gate(GatedDag.t(), any, non_neg_integer()) :: InputGate.t()
  @doc """
  Returns the input gate with the given index for the given payload.
  Raises an error if it does not exist.
  """
  def get_input_gate(gdag, payload, index) do
    input_gates =
      input_gates_for(gdag, payload)
      |> Enum.filter(fn inputgate -> inputgate.index == index end)

    case input_gates do
      [] ->
        raise "No such input gate for this dag!"

      [input_gate] ->
        input_gate

      _ ->
        raise "More than one input gate found with this index. Dag is corrupt!"
    end
  end

  @spec get_output_gate(GatedDag.t(), any, non_neg_integer()) :: OutputGate.t()
  @doc """
  Returns the output gate with the given index for the given payload.
  Raises an error if it does not exist.
  """
  def get_output_gate(gdag, payload, index) do
    output_gates =
      output_gates_for(gdag, payload)
      |> Enum.filter(fn outputgate -> outputgate.index == index end)

    case output_gates do
      [] ->
        raise "No such output gate for this dag!"

      [output_gate] ->
        output_gate

      _ ->
        raise "More than one output gate found with this index. Dag is corrupt!"
    end
  end

  @spec edges(GatedDag.t()) :: [{any, non_neg_integer(), any, non_neg_integer()}]
  @doc """
  Returns the edges between vertices, omitting the gates.

  We speak of an edge when there is the following scenario:

  vertex -> outgate -> ingate -> vertex

  This function will return lists {vertex, vertex} indicating that their in and output gates are connected.
  """
  def edges(gdag) do
    %GatedDag{edges_from: ef} = gdag

    # idag
    # |> MutableGraph.edges()
    # |> Enum.filter(fn {from, to} ->
    #   InputGate.is_inputgate?(to) and OutputGate.is_outputgate?(from)
    # end)
    # |> Enum.map(fn {from, to} ->
    #   {from.belongs_to.payload, from.index, to.belongs_to.payload, to.index}
    # end)

    Map.values(ef) |> Enum.concat()
  end

  @spec vertices_to(GatedDag.t(), any) :: [any]
  @doc """
  Returns a list of vertices that have a direct edge going to payload.
  """
  def vertices_to(gdag, payload) do
    edges(gdag)
    |> Enum.filter(fn {_, _, to, _} -> to == payload end)
    |> Enum.map(fn {from, _, _, _} -> from end)
  end

  @spec vertices_from(GatedDag.t(), any) :: [any]
  @doc """
  Returns a list of vertices that have a direct edge going to payload.
  """
  def vertices_from(gdag, payload) do
    edges(gdag)
    |> Enum.filter(fn {from, _, _, _} -> from == payload end)
    |> Enum.map(fn {_, _, to, _} -> to end)
  end

  @spec edges_to(GatedDag.t(), any) :: [{any, non_neg_integer(), any, non_neg_integer()}]
  @doc """
  Returns a list of all the edges arriving at the given payload.
  """
  def edges_to(gdag, payload) do
    # %GatedDag{edges_to: et} = gdag
    edges = edges(gdag)

    edges
    |> Enum.filter(fn {_, _, to, _} -> to == payload end)
    # Map.get(et, payload, MapSet.new()) |> Enum.to_list()
  end

  @spec edges_from(GatedDag.t(), any) :: [{any, non_neg_integer(), any, non_neg_integer()}]
  @doc """
  Returns a list of all the edges starting in the given payload.
  """
  def edges_from(gdag, payload) do
    %GatedDag{edges_from: ef} = gdag
    Map.get(ef, payload, MapSet.new()) |> Enum.to_list()
  end

  @spec dangling_outputs(GatedDag.t()) :: [any]
  @doc """
  Returns  all the output gates to which on input gate is connected.
  """
  def dangling_outputs(gdag) do
    %GatedDag{internal: idag} = gdag

    idag
    |> MutableGraph.sink_vertices()
    |> Enum.filter(&OutputGate.is_outputgate?/1)
    |> Enum.sort_by(& &1.index)
  end

  @spec dangling_inputs(GatedDag.t()) :: [any]
  @doc """
  Returns all the input gates to which no output gate is connected.
  """
  def dangling_inputs(gdag) do
    %GatedDag{internal: idag} = gdag

    idag
    |> MutableGraph.source_vertices()
    |> Enum.filter(&InputGate.is_inputgate?/1)
    |> Enum.sort_by(& &1.index)
  end

  @spec swap_vertex(GatedDag.t(), any, any) :: GatedDag.t()
  @doc """
  Given a vertex, swaps out the vertex for the other one.

  Also updates edges.
  """
  def swap_vertex(gdag, old_payload, new_payload) do
    %GatedDag{internal: idag, vertices: vs, edges_to: et, edges_from: ef} = gdag

    idag =
      idag
      |> MutableGraph.map_vertices(fn v ->
        case v do
          %Vertex{} ->
            if v.payload == old_payload, do: %{v | payload: new_payload}, else: v

          %InputGate{} ->
            if v.belongs_to.payload == old_payload,
              do: %{v | belongs_to: %{v.belongs_to | payload: new_payload}},
              else: v

          %OutputGate{} ->
            if v.belongs_to.payload == old_payload,
              do: %{v | belongs_to: %{v.belongs_to | payload: new_payload}},
              else: v
        end
      end)

    # Update set of vertices, too.
    vs =
      if MapSet.member?(vs, old_payload) do
        vs |> MapSet.delete(old_payload) |> MapSet.put(new_payload)
      else
        vs
      end

    # Replace the
    ef =
      ef
      |> Enum.reduce(%{}, fn {from, edges}, ef ->
        new_from = if from == old_payload, do: new_payload, else: from

        new_edges =
          edges
          |> Enum.reduce(MapSet.new(), fn edge, new_edges ->
            {_f, fi, t, ti} = edge
            new_to = if t == old_payload, do: new_payload, else: t

            MapSet.put(new_edges, {new_from, fi, new_to, ti})
          end)

        Map.put(ef, new_from, new_edges)
      end)

    et =
      et
      |> Enum.reduce(%{}, fn {to, edges}, et ->
        new_to = if to == old_payload, do: new_payload, else: to

        new_edges =
          edges
          |> Enum.reduce(MapSet.new(), fn edge, new_edges ->
            {f, fi, _t, ti} = edge
            new_from = if f == old_payload, do: new_payload, else: f

            MapSet.put(new_edges, {new_from, fi, new_to, ti})
          end)

        Map.put(et, new_to, new_edges)
      end)

    %{gdag | internal: idag, vertices: vs, edges_from: ef, edges_to: et}
  end

  @spec map_vertices(GatedDag.t(), (any -> any)) :: any
  @doc """
  Applies a function over all vertices in the DAG. Edges are updated too.
  """
  def map_vertices(gdag, func) do
    new_old =
      gdag
      |> vertices()
      |> Enum.reduce(%{}, fn old, new_old ->
        new = func.(old)
        Map.put(new_old, new, old)
      end)

    # All vertices have been updated, now swap them in the DAG.
    %GatedDag{internal: idag_l, edges_to: et, edges_from: ef} =
      Enum.reduce(new_old, gdag, fn {new, old}, gdag ->
        swap_vertex(gdag, old, new)
      end)

    # Update local cache of edges, too.
    %GatedDag{
      internal: idag_l,
      vertices: Map.keys(new_old) |> MapSet.new(),
      edges_from: ef,
      edges_to: et
    }
  end

  @spec merge_dags(GatedDag.t(), GatedDag.t()) :: GatedDag.t()
  @doc """
  Merges two gated dags together.

  This only works if the left gdag has `n` unconnected output gates, and the right gdag has `n` unconnect input gates.
  The gates are connected togethe.
  """
  def link_dags(gdag_l, gdag_r) do
    %GatedDag{internal: idag_l, edges_from: ef_l, edges_to: et_l} = gdag_l
    %GatedDag{internal: idag_r, edges_from: ef_r, edges_to: et_r} = gdag_r
    outputs = gdag_l |> dangling_outputs()
    inputs = gdag_r |> dangling_inputs()

    if Enum.count(outputs) != Enum.count(inputs) do
      raise "Can not link gated dags because there are not the same amount of gates open on both dags. #{Enum.count(outputs)} outputs vs #{Enum.count(inputs)} inputs."
    end

    # Merge DAGs
    idag_m = MutableGraph.merge(idag_r, idag_l)

    # Add connections between gates.
    {idag_m, ef_m, et_m} =
      outputs
      |> Enum.zip(inputs)
      |> Enum.reduce({idag_m, %{}, %{}}, fn {from, to}, {idag_m, ef, et} ->
        the_edge = {from.belongs_to.payload, from.index, to.belongs_to.payload, to.index}

        ef =
          Map.update(
            ef,
            from.belongs_to.payload,
            MapSet.new([the_edge]),
            &MapSet.put(&1, the_edge)
          )

        et =
          Map.update(et, to.belongs_to.payload, MapSet.new([the_edge]), &MapSet.put(&1, the_edge))

        {MutableGraph.add_edge(idag_m, from, to), ef, et}
      end)

    # Update the map of vertices.
    vs = MapSet.union(gdag_l.vertices, gdag_r.vertices)

    # Update the set of edges from and to.
    ef = ef_m |> Enum.into(ef_l) |> Enum.into(ef_r)
    et = et_m |> Enum.into(et_l) |> Enum.into(et_r)

    %GatedDag{internal: idag_m, vertices: vs, edges_to: et, edges_from: ef}
  end

  @doc """
  Merges two dags together but does not put links in between.
  """
  def merge_dags(gdag_l, gdag_r) do
    %GatedDag{internal: idag_l, edges_from: ef_l, edges_to: et_l} = gdag_l
    %GatedDag{internal: idag_r, edges_from: ef_r, edges_to: et_r} = gdag_r

    # Merge DAGs
    idag_m = MutableGraph.merge(idag_l, idag_r)

    vs = MapSet.union(gdag_l.vertices, gdag_r.vertices)
    ef = %{} |> Enum.into(ef_l) |> Enum.into(ef_r)
    et = %{} |> Enum.into(et_l) |> Enum.into(et_r)

    %GatedDag{internal: idag_m, vertices: vs, edges_to: et, edges_from: ef}
  end

  @spec to_dot(GatedDag.t(), (any -> String.t())) :: String.t()
  def to_dot(gdag, view_proc) do
    id_gen = fn v -> :crypto.hash(:md5, inspect(v)) |> Base.encode16() end
    edges = edges(gdag)

    generated =
      gdag
      |> vertices()
      |> Enum.reduce("", fn v, str ->
        "\"#{id_gen.(v)}\"[label=\"#{view_proc.(v)}\"]\n" <> str
      end)

    generated =
      edges
      |> Enum.reduce(generated, fn edge, str ->
        {from, fidx, to, tidx} = edge
        "\"#{id_gen.(from)}\" -> \"#{id_gen.(to)}\" [label=\"(#{fidx} -> #{tidx})\"]\n" <> str
      end)

    """
    digraph G {
    #{generated}
    }
    """
  end

  def to_dot_full(gdag, view_proc) do
    id_gen = fn v -> :crypto.hash(:md5, inspect(v)) |> Base.encode16() end

    %GatedDag{internal: dag} = gdag

    generated =
      dag
      |> MutableGraph.vertices()
      |> Enum.reduce("", fn v, str ->
        case v do
          %Vertex{} ->
            "\"#{id_gen.(v)}\"[label=\"#{view_proc.(v.payload)}\"]\n" <> str

          %InputGate{} ->
            "\"#{id_gen.(v)}\"[label=\"#{v.index}\",shape=\"invtriangle\"]\n" <> str

          %OutputGate{} ->
            "\"#{id_gen.(v)}\"[label=\"#{v.index}\",shape=\"invtriangle\"]\n" <> str
        end
      end)

    generated =
      dag
      |> MutableGraph.edges()
      |> Enum.reduce(generated, fn {from, to}, str ->
        froms = "\"#{id_gen.(from)}\""
        tos = "\"#{id_gen.(to)}\""

        "#{froms} -> #{tos}\n" <> str
      end)

    """
    digraph G {
    #{generated}
    }
    """
  end
end
