alias GatedDag, as: GD

gdag =
  GD.new()
  |> GD.add_vertex(:a, 0, 2)
  |> GD.add_vertex(:b, 1, 2)
  |> GD.add_vertex(:d, 1, 0)
  |> GD.add_vertex(:e, 1, 0)
  |> GD.add_vertex(:c, 1, 2)
  |> GD.add_vertex(:f, 1, 0)
  |> GD.add_vertex(:g, 1, 0)
  |> GD.add_edge(:a, 0, :b, 0)
  |> GD.add_edge(:a, 1, :c, 0)
  |> GD.add_edge(:b, 0, :d, 0)
  |> GD.add_edge(:b, 1, :e, 0)
  |> GD.add_edge(:c, 0, :f, 0)
  |> GD.add_edge(:c, 0, :g, 0)
