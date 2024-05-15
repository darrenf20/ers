defmodule Light do
  alias Circuits.I2C

  @addr 0x39

  # Power up light sensor
  def init(bus), do: Circuits.I2C.write(bus, @addr, <<0, 3>>)

  def read(bus) do
    data = {
      I2C.write_read(bus, @addr, <<0xAC>>, 2),
      I2C.write_read(bus, @addr, <<0xAE>>, 2)
    }
    
    case data do
      {{:ok, <<ch0::16>>}, {:ok, <<ch1::16>>}} -> data_to_lux(ch0, ch1)
      _ ->
        IO.puts("ERROR: could not read light sensor")
        nil
    end
  end

  defp data_to_lux(0, _ch1), do: 0.0
  defp data_to_lux(ch0, ch1) do
    ratio = 1.0 * ch1 / ch0

    cond do
      ratio < 0.50 ->
        0.0304 * ch0 - 0.062 * ch0 * (ratio ** 1.4)

      ratio < 0.61 ->
        0.0224 * ch0 - 0.031 * ch1

      ratio < 0.80 ->
        0.0128 * ch0 - 0.0153 * ch1

      ratio < 1.30 ->
        0.00146 * ch0 - 0.00112 * ch1

      true ->
        0.0
    end
  end
end
