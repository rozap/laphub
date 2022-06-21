defmodule LaphubWeb.LayoutView do
  use LaphubWeb, :view

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  alias Laphub.Account.User
  import Plug.Conn
  alias LaphubWeb.Icons

  def is_logged_in?(conn) do
    case get_session(conn, :user) do
      %User{} -> true
      _ -> false
    end
  end

  def user(conn), do: get_session(conn, :user)

  def user_display(conn) do
    case get_session(conn, :user) do
      %User{} = user ->
        user.display_name || user.email

      _ ->
        nil
    end
  end
end
