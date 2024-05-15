defmodule Motion do

  def read(pin), do: 1.0 * Circuits.GPIO.read(pin)
  
end
