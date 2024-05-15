defmodule MutableGraph do
  alias __MODULE__
  @type t :: %__MODULE__{}

  defstruct id_vertex: %{}, vertex_id: %{}, graph: nil, counter: 0

  @spec new :: MutableGraph.t()
  def new() do
    %MutableGraph{id_vertex: %{}, vertex_id: %{}, graph: Graph.new(), counter: 0}
  end

  ##############################################################################
  # Read

  def has_vertex?(g, n) do
    not (get_vertex(g, fn m -> n == m end) |> Enum.empty?())
  end

  @spec vertices(MutableGraph.t()) :: [any]
  def vertices(g) do
    g.vertex_id
    |> Map.keys()
  end

  @spec get_vertex(MutableGraph.t(), (any -> any)) :: [any]
  def get_vertex(g, p) do
    g
    |> vertices()
    |> Enum.filter(p)
  end

  @spec edges(MutableGraph.t()) :: [{any, any}]
  def edges(g) do
    %MutableGraph{id_vertex: ivs, graph: g_intern} = g
    # Internal edges.
    g_intern
    |> Graph.edges()
    |> Enum.map(fn %{v1: from_id, v2: to_id} ->
      {Map.get(ivs, from_id), Map.get(ivs, to_id)}
    end)
  end

  @spec vertices_to(MutableGraph.t(), any) :: [any]
  @doc """
  Returns a list of vertices which have an edge going to `n`.
  """
  def vertices_to(g, n) do
    %MutableGraph{vertex_id: vis, id_vertex: ivs, graph: g_intern} = g

    vertex_id = vis |> Map.get(n)

    g_intern
    |> Graph.edges()
    |> Enum.filter(fn %{v1: _, v2: to_id} ->
      to_id == vertex_id
    end)
    |> Enum.map(fn %{v1: id} -> id end)
    |> Enum.map(fn vertex_id -> Map.get(ivs, vertex_id) end)
  end

  @spec vertices_from(MutableGraph.t(), any) :: [any]
  @doc """
  Returns a list of vertices which have an edge incoming from `n`.
  """
  def vertices_from(g, n) do
    %MutableGraph{vertex_id: vis, id_vertex: ivs, graph: g_intern} = g

    vertex_id = vis |> Map.get(n)

    g_intern
    |> Graph.edges()
    |> Enum.filter(fn %{v1: from_id, v2: _} ->
      from_id == vertex_id
    end)
    |> Enum.map(fn %{v2: id} -> id end)
    |> Enum.map(fn vertex_id -> Map.get(ivs, vertex_id) end)
  end

  @spec source_vertices(MutableGraph.t()) :: [any]
  def source_vertices(g) do
    %MutableGraph{id_vertex: ivs, vertex_id: _, graph: g_intern, counter: _} = g

    g_intern
    |> Graph.vertices()
    |> Enum.filter(fn v ->
      Graph.in_degree(g_intern, v) == 0
    end)
    |> Enum.map(fn source_id ->
      {source_id, Map.get(ivs, source_id)}
    end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.map(fn {_k, v} -> v end)
  end

  @spec sink_vertices(MutableGraph.t()) :: [any]
  def sink_vertices(g) do
    %MutableGraph{id_vertex: ivs, vertex_id: _, graph: g_intern, counter: _} = g

    g_intern
    |> Graph.vertices()
    |> Enum.filter(fn v ->
      Graph.out_degree(g_intern, v) == 0
    end)
    |> Enum.map(fn source_id ->
      {source_id, Map.get(ivs, source_id)}
    end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.map(fn {_k, v} -> v end)
  end

  ##############################################################################
  # Write
  @spec del_vertex(MutableGraph.t(), any) :: MutableGraph.t()
  @doc """
  Deletes a vertex from the graph. All associated edges are deleted as well.
  If the vertex does not exist nothing happens.
  """
  def del_vertex(g, n) do
    %MutableGraph{id_vertex: ivs, vertex_id: vis, graph: g_intern, counter: c} = g

    #  Check if the vertex is present.
    present? = vis |> Map.has_key?(n)

    if present? do
      idx = Map.get(vis, n)
      vis = vis |> Map.delete(n)
      ivs = ivs |> Map.delete(idx)
      g_intern = Graph.delete_vertex(g_intern, idx)

      %MutableGraph{id_vertex: ivs, vertex_id: vis, graph: g_intern, counter: c}
    else
      g
    end
  end

  @spec add_vertex(MutableGraph.t(), any) :: MutableGraph.t()
  def add_vertex(g, n) do
    %MutableGraph{id_vertex: ivs, vertex_id: vis, graph: g_intern, counter: c} = g

    # Check if the vertex is already present.
    present? = vis |> Map.has_key?(n)

    if present? do
      g
    else
      ivs = %{c => n} |> Map.merge(ivs)
      vis = %{n => c} |> Map.merge(vis)

      g_intern = Graph.add_vertex(g_intern, c)
      %MutableGraph{id_vertex: ivs, vertex_id: vis, graph: g_intern, counter: c + 1}
    end
  end

  @spec add_edge(MutableGraph.t(), any, any) :: MutableGraph.t()
  def add_edge(g, from, to) do
    # Ensure the vertices have been added.
    g =
      g
      |> add_vertex(from)
      |> add_vertex(to)

    %MutableGraph{id_vertex: ivs, vertex_id: vis, graph: g_intern, counter: c} = g
    from_id = Map.get(vis, from)
    to_id = Map.get(vis, to)

    g_intern = Graph.add_edge(g_intern, from_id, to_id)

    %MutableGraph{id_vertex: ivs, vertex_id: vis, graph: g_intern, counter: c}
  end

  def add_edges(g, edges) do
    edges
    |> Enum.reduce(g, fn {from, to}, g ->
      add_edge(g, from, to)
    end)
  end

  ##############################################################################
  # Update

  @spec merge(MutableGraph.t(), MutableGraph.t()) :: MutableGraph.t()
  def merge(g1, g2) do
    # If the graph has duplicate nodes we raise an error.
    vertices1 = vertices(g1) |> MapSet.new()
    vertices2 = vertices(g2) |> MapSet.new()

    dupe_count = vertices1 |> MapSet.intersection(vertices2) |> MapSet.size()

    if dupe_count != 0 do
      raise "Duplicate values in merging graphs. Can not merge unambiguous."
    end

    g =
      g2
      |> vertices()
      |> Enum.reduce(g1, fn v, g ->
        MutableGraph.add_vertex(g, v)
      end)

    g = g2 |> edges() |> Enum.reduce(g, fn {from, to}, g -> add_edge(g, from, to) end)

    g
  end

  def map_vertices(g, f) do
    %MutableGraph{id_vertex: ivs, vertex_id: _vis, graph: g_intern, counter: c} = g

    ivs =
      ivs
      |> Enum.map(fn {k, v} ->
        {k, f.(v)}
      end)
      |> Enum.into(%{})

    vis =
      ivs
      |> Enum.map(fn {k, v} ->
        {v, k}
      end)
      |> Enum.into(%{})

    %MutableGraph{id_vertex: ivs, vertex_id: vis, graph: g_intern, counter: c}
  end

  @spec update_vertex(MutableGraph.t(), any, any) :: MutableGraph.t()
  def update_vertex(g, vertex, new_vertex) do
    %MutableGraph{id_vertex: ivs, vertex_id: vis, graph: g_intern, counter: c} = g

    present? = vis |> Map.has_key?(vertex)

    if present? do
      vertex_id = Map.get(vis, vertex)

      vis = vis |> Map.drop([vertex]) |> Map.put(new_vertex, vertex_id)
      ivs = ivs |> Map.put(vertex_id, new_vertex)

      %MutableGraph{id_vertex: ivs, vertex_id: vis, graph: g_intern, counter: c}
    else
      g
    end
  end

  def update_by(g, pred, f) do
    g
    |> vertices()
    |> Enum.filter(pred)
    |> Enum.map(fn v -> {v, f.(v)} end)
    |> Enum.reduce(g, fn {old, new}, g ->
      update_vertex(g, old, new)
    end)
  end

  ##############################################################################
  # Helpers

  @spec offset_ids(MutableGraph.t(), integer) :: MutableGraph.t()
  def offset_ids(g, i) do
    %MutableGraph{id_vertex: ivs, vertex_id: vis, graph: g_intern, counter: c} = g

    # Update the internal graph.
    g_edges =
      Graph.edges(g_intern)
      |> Enum.map(fn %Graph.Edge{v1: x, v2: y} ->
        {x + i, y + i}
      end)

    g_intern = Graph.new() |> Graph.add_edges(g_edges)

    # Update the indirection layers.
    vis = vis |> Enum.map(fn {k, v} -> {k, v + i} end) |> Enum.into(%{})
    ivs = ivs |> Enum.map(fn {k, v} -> {k + i, v} end) |> Enum.into(%{})

    %MutableGraph{id_vertex: ivs, vertex_id: vis, graph: g_intern, counter: c + i}
  end
end
