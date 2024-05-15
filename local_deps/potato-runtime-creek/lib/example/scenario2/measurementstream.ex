defmodule MeasurementStream do
  use Creek
  use Creek.MetaBehaviour

  def is_xml?({:xml, _}), do: true
  def is_xml?(_), do: false

  def is_json?({:json, _}), do: true
  def is_json?(_), do: false

  def xml_to_float({:xml, value}), do: value
  def json_to_float({:json, value}), do: value

  dag not_next as filter(&(not match?({p, :tick}, &1)))
                  ~> base

  fragment next as filter(&match?({p, :tick}, &1))
                   ~> base()
                   ~> map(fn base_result ->
                     case base_result do
                       {p, {state, :complete}} ->
                         {p, {state, :complete}}

                       {p, {state, :tick, value}} ->
                         decoded =
                           cond do
                             is_xml?(value) -> xml_to_float(value)
                             is_json?(value) -> json_to_float(value)
                             true -> value
                           end

                         {p, {state, :tick, decoded}}
                     end
                   end)

  dag encoding_meta(
        as dup
           ~> (next ||| not_next)
           ~> merge
      )

  defdag operator(src, snk) do
    src
    ~> base
    ~> effects
    ~> snk
  end

  defdag source(src, snk) do
    src
    ~> encoding_meta
    ~> effects
    ~> snk
  end

  defdag sink(src, snk) do
    src
    ~> base
    ~> effects
    ~> snk
  end

  # end
end

defmodule Slm.Streams do
  use Creek
  execution(MeasurementStream)

  defdag stream_measurements(src, snk) do
    src
    ~> snk
  end
end
