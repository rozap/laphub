defmodule LaphubWeb.AccountController do
  use LaphubWeb, :controller
  alias Laphub.Account
  import Phoenix.LiveView.Controller
  def key, do: "_Laphub_key"

  def login(conn, %{"user" => %{"email" => email, "plain_password" => password}}) do
    session_id = Map.get(conn.cookies, key())

    case Account.login(session_id, email, password) do
      {:ok, user} ->
        conn
        |> Plug.Conn.put_session(:user, user)
        |> redirect(to: "/")

      {:error, :invalid_password} ->
        conn
        |> put_flash(:error, "That password is incorrect")
        |> live_render(LaphubWeb.LoginLive)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "That account doesn't exist")
        |> live_render(LaphubWeb.LoginLive)
    end
  end

  def logout(conn, _params) do
    # :ok = Account.logout(get_session(conn, :session))

    conn
    |> clear_session
    |> put_flash(:info, "You've been logged out")
    |> redirect(to: "/")
  end

  def reset(conn, _params) do
    redirect(conn, to: "/")
  end
end
