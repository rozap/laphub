defmodule LaphubWeb.PageController do
  use LaphubWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
