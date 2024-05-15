g1 =
  MutableGraph.new()
  |> MutableGraph.add_vertex(:a)
  |> MutableGraph.add_vertex(:b)
  |> MutableGraph.add_edge(:a, :b)

%MutableGraph{id_vertex: ivs1, vertex_id: vis1, graph: g_intern1, counter: c1} = g1

g2 =
  MutableGraph.new()
  |> MutableGraph.add_vertex(:x)
  |> MutableGraph.add_vertex(:y)
  |> MutableGraph.add_edge(:x, :y)

%MutableGraph{id_vertex: ivs2, vertex_id: vis2, graph: g_intern2, counter: _} = g2

g =
  Graph.new()
  |> Graph.add_vertices([:a, :b, :c, :d])
  |> Graph.add_edge(:a, :b)
  |> Graph.add_edge(:b, :c)
  |> Graph.add_edge(:c, :d)
