defmodule MutableGraphTest do
  use ExUnit.Case
  doctest MutableGraph

  defmacro assert_sorted_equal(xs, ys) do
    quote do
      assert Enum.sort(unquote(xs)) == Enum.sort(unquote(ys))
    end
  end

  test "Create empty graph" do
    g = MutableGraph.new()
    assert MutableGraph.vertices(g) == []
    assert MutableGraph.edges(g) == []
  end

  test "Create graph with a single vertex" do
    g = MutableGraph.new() |> MutableGraph.add_vertex(:a)
    assert MutableGraph.vertices(g) == [:a]
    assert MutableGraph.edges(g) == []
  end

  test "Create graph with multiple vertices" do
    vertices = Enum.to_list(?a..?z)

    g =
      vertices
      |> Enum.reduce(MutableGraph.new(), fn v, g -> MutableGraph.add_vertex(g, v) end)

    assert MutableGraph.vertices(g) == vertices
    assert MutableGraph.edges(g) == []
  end

  test "Create graph with two vertices and an edge" do
    vertices = [:a, :b]

    g =
      vertices
      |> Enum.reduce(MutableGraph.new(), fn v, g -> MutableGraph.add_vertex(g, v) end)

    g = MutableGraph.add_edge(g, :a, :b)

    assert_sorted_equal(MutableGraph.vertices(g), vertices)

    assert_sorted_equal(MutableGraph.edges(g), [{:a, :b}])
  end

  test "Create graph with no vertices and an edge" do
    g = MutableGraph.add_edge(MutableGraph.new(), :a, :b)

    assert_sorted_equal(MutableGraph.vertices(g), [:a, :b])
    assert_sorted_equal(MutableGraph.edges(g), [{:a, :b}])
  end

  test "Update a vertex to a new value" do
    g = MutableGraph.add_edge(MutableGraph.new(), :a, :b)

    assert_sorted_equal(MutableGraph.vertices(g), [:a, :b])
    assert_sorted_equal(MutableGraph.edges(g), [{:a, :b}])

    g = MutableGraph.update_vertex(g, :a, :c)

    assert_sorted_equal(MutableGraph.vertices(g), [:b, :c])
    assert_sorted_equal(MutableGraph.edges(g), [{:c, :b}])
  end

  test "Update a vertex to a new value that's part of multiple edges" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_edge(:a, :c)
      |> MutableGraph.add_edge(:b, :c)

    assert_sorted_equal(MutableGraph.vertices(g), [:a, :b, :c])
    assert_sorted_equal(MutableGraph.edges(g), [{:b, :c}, {:a, :c}])

    g = MutableGraph.update_vertex(g, :c, :d)

    assert_sorted_equal(MutableGraph.vertices(g), [:a, :b, :d])
    assert_sorted_equal(MutableGraph.edges(g), [{:a, :d}, {:b, :d}])
  end

  test "Source nodes single source" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_edge(:a, :b)

    assert_sorted_equal(MutableGraph.source_vertices(g), [:a])
  end

  test "Source nodes multiple sources" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_vertex(:c)
      |> MutableGraph.add_edge(:a, :c)
      |> MutableGraph.add_edge(:b, :c)

    assert_sorted_equal(MutableGraph.source_vertices(g), [:a, :b])
  end

  test "Source nodes multiple sources order they were added." do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_vertex(:c)
      |> MutableGraph.add_edge(:a, :c)
      |> MutableGraph.add_edge(:b, :c)

    assert MutableGraph.source_vertices(g) == [:a, :b]
  end

  test "Source nodes no sources" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_edge(:a, :b)
      |> MutableGraph.add_edge(:b, :a)

    assert_sorted_equal(MutableGraph.source_vertices(g), [])
  end

  test "Sink nodes single sinks" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_edge(:a, :b)

    assert_sorted_equal(MutableGraph.sink_vertices(g), [:b])
  end

  test "Sink nodes multiple sinks" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_vertex(:c)
      |> MutableGraph.add_edge(:a, :c)
      |> MutableGraph.add_edge(:b, :c)

    assert_sorted_equal(MutableGraph.sink_vertices(g), [:c])
  end

  test "Sink nodes multiple  sinks preserve added order." do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_vertex(:c)
      |> MutableGraph.add_edge(:a, :b)
      |> MutableGraph.add_edge(:a, :c)

    assert MutableGraph.sink_vertices(g) == [:b, :c]
  end

  test "Sink nodes no sinks" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_edge(:a, :b)
      |> MutableGraph.add_edge(:b, :a)

    assert_sorted_equal(MutableGraph.sink_vertices(g), [])
  end

  test "Call to add_edges/2 with empty list" do
    g = MutableGraph.new() |> MutableGraph.add_edges([])

    assert_sorted_equal(MutableGraph.vertices(g), [])
    assert_sorted_equal(MutableGraph.edges(g), [])
  end

  test "Call to add_edges/2 with edges" do
    g = MutableGraph.new() |> MutableGraph.add_edges(a: :b, b: :a)

    assert_sorted_equal(MutableGraph.vertices(g), [:a, :b])
    assert_sorted_equal(MutableGraph.edges(g), [{:a, :b}, {:b, :a}])
  end

  test "Duplicate vertices can cause divergence of internal maps" do
    node = fn x -> x end

    g = MutableGraph.new() |> MutableGraph.add_vertex(node) |> MutableGraph.add_vertex(node)

    assert g.vertex_id == %{node => 0}
    assert g.id_vertex == %{0 => node}
  end

  test "Mapping over vertices" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(1)
      |> MutableGraph.add_vertex(2)
      |> MutableGraph.add_edge(1, 2)
      |> MutableGraph.map_vertices(fn x -> x + 10 end)

    assert_sorted_equal(MutableGraph.vertices(g), [11, 12])
    assert_sorted_equal(MutableGraph.edges(g), [{11, 12}])
  end

  test "Mapping over vertices resuling in duplicate vertices" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(1)
      |> MutableGraph.add_vertex(2)
      |> MutableGraph.add_edge(1, 2)
      |> MutableGraph.map_vertices(fn _ -> :a end)

    assert_sorted_equal(MutableGraph.vertices(g), [:a])
    assert_sorted_equal(MutableGraph.edges(g), [{:a, :a}])
  end

  test "Vertices_to test/1" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(1)
      |> MutableGraph.add_vertex(2)
      |> MutableGraph.add_edge(1, 2)

    assert_sorted_equal(MutableGraph.vertices_to(g, 1), [])
    assert_sorted_equal(MutableGraph.vertices_to(g, 2), [1])
    assert_sorted_equal(MutableGraph.vertices_from(g, 1), [2])
    assert_sorted_equal(MutableGraph.vertices_from(g, 2), [])
  end

  test "Vertices_to test/2" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(1)
      |> MutableGraph.add_vertex(2)

    assert_sorted_equal(MutableGraph.vertices_to(g, 1), [])
    assert_sorted_equal(MutableGraph.vertices_to(g, 2), [])
    assert_sorted_equal(MutableGraph.vertices_from(g, 1), [])
    assert_sorted_equal(MutableGraph.vertices_from(g, 2), [])
  end

  test "Vertices_to test/3" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(1)
      |> MutableGraph.add_vertex(2)
      |> MutableGraph.add_edge(1, 1)

    assert_sorted_equal(MutableGraph.vertices_to(g, 1), [1])
    assert_sorted_equal(MutableGraph.vertices_to(g, 2), [])
    assert_sorted_equal(MutableGraph.vertices_from(g, 1), [1])
    assert_sorted_equal(MutableGraph.vertices_from(g, 2), [])
  end

  test "update_by/3" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(%{n: 1, v: 1})
      |> MutableGraph.add_vertex(%{n: 2, v: 1})
      |> MutableGraph.add_edge(%{n: 1, v: 1}, %{n: 2, v: 1})
      |> MutableGraph.update_by(fn n -> n.n == 1 end, fn n -> %{n | v: 100} end)
      |> MutableGraph.update_by(fn n -> n.n == 2 end, fn n -> %{n | v: 200} end)

    assert_sorted_equal(MutableGraph.vertices(g), [%{n: 1, v: 100}, %{n: 2, v: 200}])
    assert_sorted_equal(MutableGraph.edges(g), [{%{n: 1, v: 100}, %{n: 2, v: 200}}])
  end

  test "get_vertex/2" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(%{n: 1, v: 1})
      |> MutableGraph.add_vertex(%{n: 2, v: 2})
      |> MutableGraph.add_edge(%{n: 1, v: 1}, %{n: 2, v: 2})

    assert [%{n: 1, v: 1}] == MutableGraph.get_vertex(g, fn v -> v.n == 1 end)
    assert [%{n: 2, v: 2}] == MutableGraph.get_vertex(g, fn v -> v.n == 2 end)
    assert [] == MutableGraph.get_vertex(g, fn v -> v.n == 3 end)
  end

  test "del_vertex/2 Non-existent vertex" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_edge(:a, :b)
      |> MutableGraph.del_vertex(:c)

    assert_sorted_equal(MutableGraph.vertices(g), [:a, :b])
    assert_sorted_equal(MutableGraph.edges(g), [{:a, :b}])
  end

  test "del_vertex/2" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_edge(:a, :b)
      |> MutableGraph.del_vertex(:a)

    assert_sorted_equal(MutableGraph.vertices(g), [:b])
    assert_sorted_equal(MutableGraph.edges(g), [])
  end

  test "has_vertex?/2 - existing" do
    g =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)

    assert true == MutableGraph.has_vertex?(g, :a)
    assert true == MutableGraph.has_vertex?(g, :b)
    assert false == MutableGraph.has_vertex?(g, :c)
  end
end
