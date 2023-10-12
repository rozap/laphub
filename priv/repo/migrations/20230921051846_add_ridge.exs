defmodule Laphub.Repo.Migrations.AddRidge do
  use Ecto.Migration
  import Ecto.Query
  alias Laphub.Laps.Track
  def change do
    repo().insert!(%Track{
      title: "The Ridge Motorsports Park",
      coords: [
        %{"lat" => 47.25603, "lng" => -123.19089}
      ],
      start_finish_line: [
        %{"lat" => 47.25444, "lng" => -123.19250},
        %{"lat" =>  47.25493, "lng" => -123.19250}
      ]
    })
  end
end
