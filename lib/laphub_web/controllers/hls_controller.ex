defmodule LaphubWeb.HlsController do
  use LaphubWeb, :controller
  alias Laphub.Video.VideoServer
  alias Laphub.Laps.Sesh
  alias Laphub.Repo
  alias Plug

  def index(conn, %{"session_id" => sesh_id, "filename" => filename}) do
    %Sesh{} = sesh = Repo.get(Sesh, sesh_id)
    path = VideoServer.path_to(sesh, filename)

    if File.exists?(path) do
      conn |> Plug.Conn.send_file(200, path)
    else
      conn |> Plug.Conn.send_resp(404, "File not found")
    end
  end
end
