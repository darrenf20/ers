# This script can be run from the `ers` directory,
# in the terminal, using:
# `elixir sloc.exs`

defmodule SLOC do

  def count() do
    app_files = [
      "lib/collector.ex", 
      "lib/measurements.ex",
      "lib/http.ex",
    ]

    sensor_files = [
      "lib/motion.ex",
      "lib/temperature.ex",
      "lib/soundlevel.ex",
      "lib/co2sensor.ex",
      "lib/light.ex",
    ]

    db_files = [
      "lib/supervisor.ex",
      "lib/reading.ex",
      "lib/repo.ex",
      "config/config.exs",
      hd(Path.wildcard("priv/repo/migrations/*")),
    ]
  
    deps_files = [
      "mix.exs"
    ]

    collection = [
     {"Application", app_files},
     {"Sensor", sensor_files},
     {"Database configuration", db_files},
     {"Dependency management", deps_files}
    ]

    totals = Enum.map(collection, &print_files_counts/1)

    IO.puts("============\nTOTAL: #{Enum.sum(totals)}")
    
  end

  defp print_files_counts({heading, files}) do
    IO.puts(heading <> "\n---------------------------")

    l = Enum.map(files, fn f -> {f, count_lines(f)} end)

    l |> Enum.map(fn {f, c} -> IO.puts("#{f}: #{c}") end)

    s = l |> Enum.map(fn {_f, c} -> c end) |> Enum.sum()

    IO.puts("---------------------------\nSub-total: #{s}\n")

    s
  end

  defp count_lines(path) do
    path
    |> File.open!([:utf8], &IO.read(&1, :eof)) # Read the whole file
    |> String.split("\n") # Get lines
    |> Enum.map(&String.trim/1) # Remove whitespace
    |> Enum.filter(fn s -> String.length(s) > 0 and String.first(s) != "#" end) # Filter out comments, empty lines
    |> length() # Sum number of lines
  end

end


SLOC.count() 
