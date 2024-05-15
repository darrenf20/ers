import Config

config :ers, Repo,
  database: "ers",
  # Edit the following with your details
  username: "darren",
  password: "password",
  hostname: "localhost"

config :ers, ecto_repos: [Repo]

