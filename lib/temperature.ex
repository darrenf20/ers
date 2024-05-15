defmodule Temperature do
  alias Circuits.I2C

  @addr 0x48

  def read(bus) do
    case I2C.read(bus, @addr, 2) do
      {:ok, <<a::8, b::4, _::4>>} ->
        <<x::16>> = <<0::4, a::8, b::4>>
        0.0625 * x
      _ ->
        IO.puts("ERROR: could not read temperature sensor")
        nil
    end
  end

end
