# defimpl Inspect, for: MutableGraph do
#   def inspect(
#         %MutableGraph{id_vertex: _, vertex_id: vis, graph: _g_intern, counter: c} = g,
#         _opts
#       ) do
#     edges =
#       MutableGraph.edges(g)
#       |> Enum.map(fn {from, to} ->
#         "#{inspect from} ~> #{inspect to}"
#       end)
#       |> Enum.join(", ")

#     ~s(#<MutableGraph<vertices: #{inspect(Map.keys(vis))}, edges: #{edges}, counter: #{c}>)
#   end
# end
