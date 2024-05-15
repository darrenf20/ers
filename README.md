# ERS

First, get the dependencies:  
`mix deps.get`

To re-create the database, run the following commands:  
`mix ecto.drop`  
`mix ecto.create`  
`mix ecto.migrate`   

Start the server with, e.g. 

`iex --sname bob --cookie secret -S mix`  
`ERS.Server.Measurements.run`

Start the sensor node with, e.g. 

`iex --sname alice --cookie secret -S mix`  
`ERS.Client.Collector.run`
