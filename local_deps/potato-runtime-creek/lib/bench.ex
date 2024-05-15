defmodule Bench  do
  def write() do
    Process.sleep(60000)
    memory = :erlang.memory  |> Keyword.pop(:total) |> elem(0)
    File.write("#{node()}.txt", "#{memory}", [:append, {:encoding, :utf8}])
  end
end
