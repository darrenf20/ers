defmodule HTTP do
  import Plug.Conn
  import Ecto.Query

  @node "pi12"

  def init(options), do: options

  def call(conn, _opts) do
    query =
      from(r1 in Reading,
        left_join: r2 in Reading,
        on: r1.sensor_type == r2.sensor_type and r1.timestamp < r2.timestamp,
        where: r1.node_name == @node and is_nil(r2.sensor_type),
        select: {r1.timestamp, r1.sensor_type, r1.value})
      |> Repo.all
    
    {time, _, _} = Enum.at(query, 0)
    
    q =
      query 
      |> Enum.sort
      |> Enum.map(fn {_, s, v} ->
        "#{String.capitalize(s)}: #{if is_nil(v), do: "NULL", else: Float.round(v, 2)}"
      end)

    resp = """
    <html><body>
    <h1>ERS</h1><h3>Node: #{@node}</h3>
    <h3>Timestamp: #{DateTime.from_unix!(time)}</h3><h2>#{Enum.join(q, "<br>")}</h2>
    <script>setInterval(function() { location.reload() }, 3000);</script>
    </body></html> 
    """

    conn |> put_resp_content_type("text/html") |> send_resp(200, resp)
  end

  def run() do
    ERS.Supervisor.start_link([])
    Plug.Cowboy.http(__MODULE__, [], port: 8080)
  end
end
