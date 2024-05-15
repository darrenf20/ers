defmodule GatedDagTest do
  use ExUnit.Case
  doctest GatedDag

  alias GatedDag, as: GD
  alias GatedDag.{InputGate, OutputGate, Vertex}

  defmacro assert_sorted_equal(xs, ys) do
    quote do
      assert Enum.sort(unquote(xs)) == Enum.sort(unquote(ys))
    end
  end

  describe "new/0" do
    test "create gated dag." do
      gdag = GD.new()
      assert_sorted_equal(GD.edges(gdag), [])
      assert_sorted_equal(GD.vertices(gdag), [])
    end
  end

  describe "add_vertex/4, edges/1, and vertices/1" do
    test "add vertex without gates" do
      gdag = GD.new() |> GD.add_vertex(:a, 0, 0)
      assert_sorted_equal(GD.edges(gdag), [])
      assert_sorted_equal(GD.vertices(gdag), [:a])
    end

    test "Add vertex with input gate" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 0)
      assert_sorted_equal(GD.edges(gdag), [])
      assert_sorted_equal(GD.vertices(gdag), [:a])
    end

    test "Add vertex with output gate" do
      gdag = GD.new() |> GD.add_vertex(:a, 0, 1)
      assert_sorted_equal(GD.edges(gdag), [])
      assert_sorted_equal(GD.vertices(gdag), [:a])
    end

    test "Add vertex with  gates" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1)
      assert_sorted_equal(GD.edges(gdag), [])
      assert_sorted_equal(GD.vertices(gdag), [:a])
    end

    test "Add vertex with lots of gates" do
      gdag = GD.new() |> GD.add_vertex(:a, 10, 10)
      assert_sorted_equal(GD.edges(gdag), [])
      assert_sorted_equal(GD.vertices(gdag), [:a])
    end

    test "Add second vertex" do
      gdag =
        GD.new()
        |> GD.add_vertex(:a, 10, 10)
        |> GD.add_vertex(:b, 10, 10)

      assert_sorted_equal(GD.edges(gdag), [])
      assert_sorted_equal(GD.vertices(gdag), [:a, :b])
    end
  end

  describe "del_vertex/2" do
    test "Add and remove same vertex" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1) |> GD.del_vertex(:a)
      assert_sorted_equal(GD.edges(gdag), [])
      assert_sorted_equal(GD.vertices(gdag), [])
    end

    test "Add and remove same vertex, but keep one" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1) |> GD.add_vertex(:b, 1, 1) |> GD.del_vertex(:a)
      assert_sorted_equal(GD.edges(gdag), [])
      assert_sorted_equal(GD.vertices(gdag), [:b])
    end

    test "Add and remove same vertex, but keep one, and check the edges" do
      gdag =
        GD.new()
        |> GD.add_vertex(:a, 1, 1)
        |> GD.add_vertex(:b, 1, 1)
        |> GD.add_edge(:a, 0, :b, 0)
        |> GD.del_vertex(:a)

      assert_sorted_equal(GD.edges(gdag), [])
      assert_sorted_equal(GD.vertices(gdag), [:b])
    end

    @tag :fail
    test "Add and remove same vertex, but keep two, and check the edges" do
      gdag =
        GD.new()
        |> GD.add_vertex(:a, 1, 1)
        |> GD.add_vertex(:b, 1, 1)
        |> GD.add_vertex(:c, 1, 1)
        |> GD.add_edge(:a, 0, :b, 0)
        |> GD.add_edge(:b, 0, :c, 0)
        |> GD.del_vertex(:a)

      assert_sorted_equal(GD.edges(gdag), [{:b, 0, :c, 0}])
      assert_sorted_equal(GD.vertices(gdag), [:b, :c])
      assert_sorted_equal(GD.edges_from(gdag, :a), [])
      assert_sorted_equal(GD.edges_to(gdag, :a), [])

      assert_sorted_equal(GD.edges_from(gdag, :b), [{:b, 0, :c, 0}])
      assert_sorted_equal(GD.edges_to(gdag, :b), [])

      assert_sorted_equal(GD.edges_from(gdag, :c), [])
      assert_sorted_equal(GD.edges_to(gdag, :c), [{:b, 0, :c, 0}])
    end
  end

  describe "input_gates_for/2, output_gates_for/2, and indegree/2" do
    test "test no gates" do
      gdag = GD.new() |> GD.add_vertex(:a, 0, 0)

      assert_sorted_equal(GD.input_gates_for(gdag, :a), [])

      assert_sorted_equal(GD.output_gates_for(gdag, :a), [])

      assert 0 = GD.indegree(gdag, :a)
      assert 0 = GD.outdegree(gdag, :a)
    end

    test "test one of both gates" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1)

      assert_sorted_equal(GD.input_gates_for(gdag, :a), [
        %InputGate{belongs_to: %Vertex{payload: :a}, index: 0}
      ])

      assert_sorted_equal(GD.output_gates_for(gdag, :a), [
        %OutputGate{belongs_to: %Vertex{payload: :a}, index: 0}
      ])

      assert 1 = GD.indegree(gdag, :a)
      assert 1 = GD.outdegree(gdag, :a)
    end

    test "Two operators, one gate of each" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1) |> GD.add_vertex(:b, 1, 1)

      assert_sorted_equal(GD.input_gates_for(gdag, :a), [
        %InputGate{belongs_to: %Vertex{payload: :a}, index: 0}
      ])

      assert_sorted_equal(GD.output_gates_for(gdag, :a), [
        %OutputGate{belongs_to: %Vertex{payload: :a}, index: 0}
      ])

      assert 1 = GD.indegree(gdag, :a)
      assert 1 = GD.outdegree(gdag, :a)

      assert_sorted_equal(GD.input_gates_for(gdag, :b), [
        %InputGate{belongs_to: %Vertex{payload: :b}, index: 0}
      ])

      assert_sorted_equal(GD.output_gates_for(gdag, :b), [
        %OutputGate{belongs_to: %Vertex{payload: :b}, index: 0}
      ])

      assert 1 = GD.indegree(gdag, :b)
      assert 1 = GD.outdegree(gdag, :b)
    end
  end

  describe "get_output_gate/3 and get_input_gate/3" do
    test "no gates" do
      gdag = GD.new()

      assert_raise RuntimeError, "No such input gate for this dag!", fn ->
        GD.get_input_gate(gdag, :a, 0)
      end
    end

    test "one input gate and one output gate" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1) |> GD.add_vertex(:b, 1, 1)

      assert %InputGate{belongs_to: %Vertex{payload: :a}, index: 0} =
               GD.get_input_gate(gdag, :a, 0)

      assert %OutputGate{belongs_to: %Vertex{payload: :a}, index: 0} =
               GD.get_output_gate(gdag, :a, 0)
    end
  end

  describe "dangling_outputs/1" do
    test "empty dag" do
      gdag = GD.new()

      assert_sorted_equal([], GD.dangling_inputs(gdag))
      assert_sorted_equal([], GD.dangling_outputs(gdag))
    end

    test "dag with one operator, no gates" do
      gdag = GD.new() |> GD.add_vertex(:a, 0, 0)

      assert_sorted_equal([], GD.dangling_inputs(gdag))
      assert_sorted_equal([], GD.dangling_outputs(gdag))
    end

    test "dag with one operator, only output gate" do
      gdag = GD.new() |> GD.add_vertex(:a, 0, 1)

      assert_sorted_equal([], GD.dangling_inputs(gdag))

      assert_sorted_equal(
        [%OutputGate{belongs_to: %Vertex{payload: :a}, index: 0}],
        GD.dangling_outputs(gdag)
      )
    end

    test "dag with one operator, only output gate and one input gate" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1)

      assert_sorted_equal(
        [%InputGate{belongs_to: %Vertex{payload: :a}, index: 0}],
        GD.dangling_inputs(gdag)
      )

      assert_sorted_equal(
        [%OutputGate{belongs_to: %Vertex{payload: :a}, index: 0}],
        GD.dangling_outputs(gdag)
      )
    end
  end

  describe "link_dags/2" do
    test "Link empty dags" do
      gdag_l = GD.new()
      gdag_r = GD.new()

      gdag_m = GD.link_dags(gdag_l, gdag_r)

      assert_sorted_equal([], GD.edges(gdag_m))
      assert_sorted_equal([], GD.vertices(gdag_m))
    end

    test "Link two non-empty dags" do
      gdag_l = GD.new() |> GD.add_vertex(:a, 1, 1)
      gdag_r = GD.new() |> GD.add_vertex(:b, 1, 1)

      gdag_m = GD.link_dags(gdag_l, gdag_r)

      assert_sorted_equal([{:a, 0, :b, 0}], GD.edges(gdag_m))
      assert_sorted_equal([{:a, 0, :b, 0}], GD.edges_from(gdag_m, :a))
      assert_sorted_equal([{:a, 0, :b, 0}], GD.edges_to(gdag_m, :b))
      assert_sorted_equal([], GD.edges_from(gdag_m, :b))
      assert_sorted_equal([], GD.edges_to(gdag_m, :a))
      assert_sorted_equal([:a, :b], GD.vertices(gdag_m))
    end

    test "Link two non-empty dags enforce order" do
      gdag_l = GD.new() |> GD.add_vertex(:a, 1, 1) |> GD.add_vertex(:b, 1, 1)
      gdag_r = GD.new() |> GD.add_vertex(:x, 1, 1) |> GD.add_vertex(:y, 1, 1)

      gdag_m = GD.link_dags(gdag_l, gdag_r)

      assert_sorted_equal([{:a, 0, :x, 0}, {:b, 0, :y, 0}], GD.edges(gdag_m))
      assert_sorted_equal([:a, :b, :x, :y], GD.vertices(gdag_m))
    end

    test "Link two non-empty dags multiple gates" do
      gdag_l = GD.new() |> GD.add_vertex(:a, 1, 2)
      gdag_r = GD.new() |> GD.add_vertex(:b, 2, 1)

      gdag_m = GD.link_dags(gdag_l, gdag_r)

      assert_sorted_equal([{:a, 0, :b, 0}, {:a, 1, :b, 1}], GD.edges(gdag_m))
      assert_sorted_equal([:a, :b], GD.vertices(gdag_m))
    end

    test "Link two non-empty dags multiple gates and mismatching amount" do
      gdag_l = GD.new() |> GD.add_vertex(:a, 1, 2)
      gdag_r = GD.new() |> GD.add_vertex(:b, 3, 1)

      assert_raise RuntimeError,
                   "Can not link gated dags because there are not the same amount of gates open on both dags. 2 outputs vs 3 inputs.",
                   fn -> GD.link_dags(gdag_l, gdag_r) end
    end
  end

  describe "merge_dags/2" do
    test "Merge empty dags" do
      gdag_l = GD.new()
      gdag_r = GD.new()

      gdag_m = GD.merge_dags(gdag_l, gdag_r)

      assert_sorted_equal([], GD.edges(gdag_m))
      assert_sorted_equal([], GD.vertices(gdag_m))
    end

    test "Merge two non-empty dags" do
      gdag_l = GD.new() |> GD.add_vertex(:a, 1, 1)
      gdag_r = GD.new() |> GD.add_vertex(:b, 1, 1)

      gdag_m = GD.merge_dags(gdag_l, gdag_r)

      assert_sorted_equal([], GD.edges(gdag_m))
      assert_sorted_equal([:a, :b], GD.vertices(gdag_m))
    end

    test "Merge two non-empty dags multiple gates" do
      gdag_l = GD.new() |> GD.add_vertex(:a, 1, 2)
      gdag_r = GD.new() |> GD.add_vertex(:b, 2, 1)

      gdag_m = GD.merge_dags(gdag_l, gdag_r)

      assert_sorted_equal([], GD.edges(gdag_m))
      assert_sorted_equal([:a, :b], GD.vertices(gdag_m))
    end

    test "Merge two non-empty dags multiple gates and mismatching amount" do
      gdag_l = GD.new() |> GD.add_vertex(:a, 1, 2)
      gdag_r = GD.new() |> GD.add_vertex(:b, 3, 1)

      gdag_m = GD.merge_dags(gdag_l, gdag_r)
      assert_sorted_equal([], GD.edges(gdag_m))
      assert_sorted_equal([:a, :b], GD.vertices(gdag_m))
    end

    test "Merge two non-empty dags multiple vertices in each dag" do
      gdag_l =
        GD.new()
        |> GD.add_vertex(:a, 1, 1)
        |> GD.add_vertex(:b, 1, 1)
        |> GD.add_edge(:a, 0, :b, 0)

      gdag_r =
        GD.new()
        |> GD.add_vertex(:x, 3, 1)
        |> GD.add_vertex(:y, 1, 1)
        |> GD.add_edge(:x, 0, :y, 0)

      gdag_m = GD.merge_dags(gdag_l, gdag_r)
      assert_sorted_equal([{:a, 0, :b, 0}, {:x, 0, :y, 0}], GD.edges(gdag_m))
      assert_sorted_equal([:a, :b, :x, :y], GD.vertices(gdag_m))
    end
  end

  describe "add_edge/5" do
    test "Add an edge to an empty DAG." do
      assert_raise RuntimeError, "No such output gate for this dag!", fn ->
        GD.new() |> GD.add_edge(:a, 1, :b, 1)
      end
    end

    test "Add an edge from own output to own input." do
      gdag =
        GD.new()
        |> GD.add_vertex(:a, 1, 1)
        |> GD.add_edge(:a, 0, :a, 0)

      assert_sorted_equal([{:a, 0, :a, 0}], GD.edges(gdag))
      assert_sorted_equal([:a], GD.vertices(gdag))
    end

    test "Add an edge from one node to another" do
      gdag =
        GD.new()
        |> GD.add_vertex(:a, 1, 1)
        |> GD.add_vertex(:b, 1, 1)
        |> GD.add_edge(:a, 0, :b, 0)

      assert_sorted_equal([{:a, 0, :b, 0}], GD.edges(gdag))
      assert_sorted_equal([:a, :b], GD.vertices(gdag))
    end
  end

  describe "edges_from/2 and edges_to/2" do
    test "get edges from new graph" do
      gdag = GD.new()

      assert_sorted_equal([], GD.edges_from(gdag, :a))
      assert_sorted_equal([], GD.edges_to(gdag, :a))
    end

    test "get vertices from new graph" do
      gdag = GD.new()

      assert_sorted_equal([], GD.vertices_from(gdag, :a))
      assert_sorted_equal([], GD.vertices_to(gdag, :a))
    end

    test "get edges from new graph with single vertex" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1)

      assert_sorted_equal([], GD.edges_from(gdag, :a))
      assert_sorted_equal([], GD.edges_to(gdag, :a))
    end

    test "get vertices from new graph with single vertex" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1)

      assert_sorted_equal([], GD.edges_from(gdag, :a))
      assert_sorted_equal([], GD.edges_to(gdag, :a))
    end

    test "get edges from new graph with single vertex and edge to self" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1) |> GD.add_edge(:a, 0, :a, 0)

      assert_sorted_equal([{:a, 0, :a, 0}], GD.edges_from(gdag, :a))
      assert_sorted_equal([{:a, 0, :a, 0}], GD.edges_to(gdag, :a))
    end

    test "get vertices from new graph with single vertex and edge to self" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1) |> GD.add_edge(:a, 0, :a, 0)

      assert_sorted_equal([:a], GD.vertices_from(gdag, :a))
      assert_sorted_equal([:a], GD.vertices_to(gdag, :a))
    end

    test "get edges from new graph with two vertex and edge to eachother" do
      gdag =
        GD.new()
        |> GD.add_vertex(:a, 1, 1)
        |> GD.add_vertex(:b, 1, 1)
        |> GD.add_vertex(:c, 1, 1)
        |> GD.add_edge(:a, 0, :b, 0)
        |> GD.add_edge(:b, 0, :c, 0)

      assert_sorted_equal([{:a, 0, :b, 0}], GD.edges_from(gdag, :a))
      assert_sorted_equal([], GD.edges_to(gdag, :a))

      assert_sorted_equal([{:a, 0, :b, 0}], GD.edges_to(gdag, :b))
      assert_sorted_equal([{:b, 0, :c, 0}], GD.edges_from(gdag, :b))

      assert_sorted_equal([{:b, 0, :c, 0}], GD.edges_to(gdag, :c))
      assert_sorted_equal([], GD.edges_from(gdag, :c))
    end

    test "get vertices from new graph with two vertex and edge to eachother" do
      gdag =
        GD.new()
        |> GD.add_vertex(:a, 1, 1)
        |> GD.add_vertex(:b, 1, 1)
        |> GD.add_edge(:a, 0, :b, 0)

      assert_sorted_equal([:b], GD.vertices_from(gdag, :a))
      assert_sorted_equal([:a], GD.vertices_to(gdag, :b))
    end
  end

  describe "swap_vertex/3 and map_vertices/2" do
    test "swap empty graph" do
      gdag = GD.new() |> GD.swap_vertex(:a, :b)

      assert_sorted_equal([], GD.edges(gdag))
      assert_sorted_equal([], GD.vertices(gdag))
    end

    test "swap over vertices" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1) |> GD.swap_vertex(:a, :b)
      assert_sorted_equal([], GD.edges(gdag))
      assert_sorted_equal([:b], GD.vertices(gdag))
    end

    test "swap over vertices with edges" do
      gdag =
        GD.new()
        |> GD.add_vertex(:a, 1, 1)
        |> GD.add_vertex(:b, 1, 1)
        |> GD.add_edge(:a, 0, :b, 0)
        |> GD.swap_vertex(:a, :c)

      assert_sorted_equal([{:c, 0, :b, 0}], GD.edges(gdag))
      assert_sorted_equal([:c, :b], GD.vertices(gdag))
    end

    test "Map over empty DAG" do
      gdag = GD.new() |> GD.map_vertices(fn _x -> 1 end)

      assert_sorted_equal([], GD.edges(gdag))
      assert_sorted_equal([], GD.vertices(gdag))
    end

    test "map over vertices" do
      gdag = GD.new() |> GD.add_vertex(:a, 1, 1) |> GD.map_vertices(fn x -> "#{x}" end)
      assert_sorted_equal([], GD.edges(gdag))
      assert_sorted_equal(["a"], GD.vertices(gdag))
    end

    test "map over vertices with edges" do
      gdag =
        GD.new()
        |> GD.add_vertex(:a, 1, 1)
        |> GD.add_vertex(:b, 1, 1)
        |> GD.add_edge(:a, 0, :b, 0)
        |> GD.map_vertices(fn x -> "#{x}" end)

      assert_sorted_equal([{"a", 0, "b", 0}], GD.edges(gdag))
      assert_sorted_equal(["a", "b"], GD.vertices(gdag))
    end

    test "Only one side effect with mapping" do
      testpid = self()

      gdag =
        GD.new()
        |> GD.add_vertex(:a, 1, 1)
        |> GD.add_vertex(:b, 1, 1)
        |> GD.add_edge(:a, 0, :b, 0)
        |> GD.map_vertices(fn x ->
          send(testpid, :effect)
          "#{x}"
        end)

      Process.sleep(100)
      assert_receive :effect
      assert_receive :effect

      empty? =
        receive do
          _ -> false
        after
          0 ->
            true
        end

      assert empty? == true

      assert_sorted_equal([{"a", 0, "b", 0}], GD.edges(gdag))
      assert_sorted_equal(["a", "b"], GD.vertices(gdag))
    end
  end

  @tag :fail
  describe "breadth_first_tarversal" do
    test "Test order" do
      #        a
      #     b     c
      #    d e   f g
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

      assert [:g, :f, :e, :d, :c, :b, :a] == GD.breadth_first_reduce(gdag, &[&1 | &2], [])
    end
  end
end
