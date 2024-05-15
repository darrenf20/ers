defmodule Repo do
  use Ecto.Repo,
    otp_app: :ers,
    adapter: Ecto.Adapters.MyXQL
end
