defmodule MdlApps.Repo do
  use Ecto.Repo,
    otp_app: :mdl_apps,
    adapter: Ecto.Adapters.Postgres
end
