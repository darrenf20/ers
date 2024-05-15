defmodule MergeMutableGraphTest do
  use ExUnit.Case
  doctest MutableGraph

  defmacro assert_sorted_equal(xs, ys) do
    quote do
      assert Enum.sort(unquote(xs)) == Enum.sort(unquote(ys))
    end
  end

  test "Merge two empty graphs" do
    g1 = MutableGraph.new()
    g2 = MutableGraph.new()

    g = MutableGraph.merge(g1, g2)

    assert MutableGraph.vertices(g) == []
    assert MutableGraph.edges(g) == []

    g = MutableGraph.merge(g2, g1)

    assert MutableGraph.vertices(g) == []
    assert MutableGraph.edges(g) == []
  end

  test "Merge an empty graph with a single-node graph" do
    g1 = MutableGraph.new() |> MutableGraph.add_vertex(:a)
    g2 = MutableGraph.new()

    g = MutableGraph.merge(g1, g2)

    assert MutableGraph.vertices(g) == [:a]
    assert MutableGraph.edges(g) == []

    # Other way around
    g = MutableGraph.merge(g2, g1)

    assert MutableGraph.vertices(g) == [:a]
    assert MutableGraph.edges(g) == []
  end

  test "Merge two graphs with single node" do
    g1 = MutableGraph.new() |> MutableGraph.add_vertex(:a)
    g2 = MutableGraph.new() |> MutableGraph.add_vertex(:b)

    g = MutableGraph.merge(g1, g2)

    assert_sorted_equal(MutableGraph.vertices(g), [:a, :b])
    assert_sorted_equal(MutableGraph.edges(g), [])

    # Other way around
    g = MutableGraph.merge(g2, g1)

    assert_sorted_equal(MutableGraph.vertices(g), [:a, :b])
    assert_sorted_equal(MutableGraph.edges(g), [])
  end

  test "Merge two graphs with same vertex" do
    g1 = MutableGraph.new() |> MutableGraph.add_vertex(:a)
    g2 = MutableGraph.new() |> MutableGraph.add_vertex(:a)

    assert_raise RuntimeError,
                 "Duplicate values in merging graphs. Can not merge unambiguous.",
                 fn ->
                   MutableGraph.merge(g1, g2)
                 end

    # Other way around
    assert_raise RuntimeError,
                 "Duplicate values in merging graphs. Can not merge unambiguous.",
                 fn ->
                   MutableGraph.merge(g2, g1)
                 end
  end

  test "Merge two graphs with same vertices" do
    g1 = MutableGraph.new() |> MutableGraph.add_vertex(:a) |> MutableGraph.add_vertex(:b)
    g2 = MutableGraph.new() |> MutableGraph.add_vertex(:a) |> MutableGraph.add_vertex(:b)

    assert_raise RuntimeError,
                 "Duplicate values in merging graphs. Can not merge unambiguous.",
                 fn ->
                   MutableGraph.merge(g1, g2)
                 end

    # Other way around
    assert_raise RuntimeError,
                 "Duplicate values in merging graphs. Can not merge unambiguous.",
                 fn ->
                   MutableGraph.merge(g2, g1)
                 end
  end

  test "Merge two graphs with overlapping vertices" do
    g1 = MutableGraph.new() |> MutableGraph.add_vertex(:a) |> MutableGraph.add_vertex(:c)
    g2 = MutableGraph.new() |> MutableGraph.add_vertex(:a) |> MutableGraph.add_vertex(:b)

    assert_raise RuntimeError,
                 "Duplicate values in merging graphs. Can not merge unambiguous.",
                 fn ->
                   MutableGraph.merge(g1, g2)
                 end
  end

  test "Merge two graphs with distinct vertices and edges" do
    g1 =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_edge(:a, :b)

    g2 =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:x)
      |> MutableGraph.add_vertex(:y)
      |> MutableGraph.add_edge(:x, :y)

    g = MutableGraph.merge(g1, g2)

    assert_sorted_equal(MutableGraph.vertices(g), [:a, :b, :x, :y])
    assert_sorted_equal(MutableGraph.edges(g), [{:x, :y}, {:a, :b}])

    # Other way around
    g = MutableGraph.merge(g2, g1)

    assert_sorted_equal(MutableGraph.vertices(g), [:a, :b, :x, :y])
    assert_sorted_equal(MutableGraph.edges(g), [{:x, :y}, {:a, :b}])
  end

  test "Merge two graphs with overlapping vertices and edges" do
    g1 =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_edge(:a, :b)

    g2 =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:x)
      |> MutableGraph.add_vertex(:b)
      |> MutableGraph.add_edge(:x, :b)

    assert_raise RuntimeError,
                 "Duplicate values in merging graphs. Can not merge unambiguous.",
                 fn ->
                   MutableGraph.merge(g1, g2)
                 end

    # Other way around
    assert_raise RuntimeError,
                 "Duplicate values in merging graphs. Can not merge unambiguous.",
                 fn ->
                   MutableGraph.merge(g2, g1)
                 end
  end

  test "Add vertex to merged graph to ensure counter works as expected." do
    g1 =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)

    g2 =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:x)
      |> MutableGraph.add_vertex(:y)

    g = MutableGraph.merge(g1, g2)

    vertices = Enum.to_list(?a..?z)

    g =
      vertices
      |> Enum.reduce(g, fn v, g -> MutableGraph.add_vertex(g, v) end)

    assert_sorted_equal(MutableGraph.vertices(g), vertices ++ [:a, :b, :x, :y])
    assert_sorted_equal(MutableGraph.edges(g), [])
  end

  test "Add vertex to merged graph and edges to ensure counter works as expected." do
    g1 =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:a)
      |> MutableGraph.add_vertex(:b)

    g2 =
      MutableGraph.new()
      |> MutableGraph.add_vertex(:x)
      |> MutableGraph.add_vertex(:y)

    g = MutableGraph.merge(g1, g2)

    vertices = Enum.to_list(?a..?z)

    g =
      vertices
      |> Enum.reduce(g, fn v, g -> MutableGraph.add_vertex(g, v) end)
      |> MutableGraph.add_edge(:a, :x)
      |> MutableGraph.add_edge(:a, ?x)

    assert_sorted_equal(MutableGraph.vertices(g), vertices ++ [:a, :b, :x, :y])
    assert_sorted_equal(MutableGraph.edges(g), [{:a, :x}, {:a, ?x}])
  end

  test "Duplicate vertices on merge raise an error" do
    node = fn x -> x end

    g1 = MutableGraph.new() |> MutableGraph.add_vertex(node)
    g2 = MutableGraph.new() |> MutableGraph.add_vertex(node)

    assert_raise RuntimeError,
                 "Duplicate values in merging graphs. Can not merge unambiguous.",
                 fn ->
                   MutableGraph.merge(g1, g2)
                 end
  end
end
