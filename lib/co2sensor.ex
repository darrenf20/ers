# This module is for the CJMCU-811 / CCS811 sensor.
# Set `dtparam=i2c_baudrate=9500` in Raspberry Pi's
# `/boot/config.txt` file.

defmodule CO2Sensor do
  
  @addr 0x5A

  def read(bus) do
    # If there isn't valid data available...
    if Circuits.I2C.write_read(bus, @addr, <<0x00>>, 1) != 0b10011000 do

      # Read error register to clear it
      Circuits.I2C.write_read(bus, @addr, <<0xE0>>, 1)

      # Put sensor in application mode
      Circuits.I2C.write_read(bus, @addr, <<0xF4>>, 0)

      # Set sensor to read every second (mode 1)
      Circuits.I2C.write_read(bus, @addr, <<0x01, 0x10>>, 0)
    end

    case Circuits.I2C.write_read(bus, @addr, <<0x02>>, 2) do
      {:ok, <<x::16>>} -> 1.0 * x
      _ ->
        IO.puts("ERROR: could not read co2 sensor")
        nil
    end
  end

end
