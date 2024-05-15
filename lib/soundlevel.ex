defmodule SoundLevel do
  alias Circuits.SPI

  @spi_bus "spidev0.0"
  
  @sample_hz 20
  @sample_period 1
  
  @sleep_time Kernel.trunc(1.0 / @sample_hz * 1000)
  @num_samples Kernel.trunc(@sample_period / (@sleep_time / 1000))

  def read() do
    samples = get_samples(@num_samples, [])
    median(samples)
  end

  defp get_samples(0, acc), do: acc
  defp get_samples(n, acc) when n > 0 do
    {:ok, bus} = SPI.open(@spi_bus)
    data = SPI.transfer(bus, <<0xD0, 0x00, 0x00>>)
    SPI.close(bus)
    
    case data do
      {:ok, <<_::5, a::3, b::7, _::9>>} ->
        <<x::16>> = <<0::6, a::3, b::7>>
        Process.sleep(@sleep_time)
        get_samples(n - 1, [x | acc])
      _ ->
        IO.puts("ERROR: could not read sound sensor")
        nil
    end

  end

  defp median(nil), do: nil
  defp median(list) do
    l = Enum.sort(list)
    len = length(l)

    cond do
      rem(len, 2) == 0 ->
        (Enum.at(l, div(len, 2) - 1) + Enum.at(l, div(len, 2))) / 2

      true ->
        Enum.at(l, div(l, 2))
    end
  end
  
end
