defmodule LaphubWeb.LoginLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  import LaphubWeb.Gettext
  import LaphubWeb.ErrorHelpers
  alias Laphub.Account
  alias LaphubWeb.Router.Helpers, as: Routes
  require Logger

  def mount(_params, _wut, socket) do
    {:ok, assign(socket, email: "", password: "", trigger_submit: false)}
  end

  def handle_event(
        "save",
        %{"user" => %{"email" => email, "plain_password" => password}},
        socket
      ) do
    socket = assign(socket, email: email, password: password)
    if Account.is_valid_email_password?(email, password) do
      Logger.info("#{email} has logged in")
      {:noreply, assign(socket, trigger_submit: true)}
    else
      Logger.info("#{email} failed to log in")
      {:noreply, put_flash(socket, :error, "Invalid username or password")}
    end
  end


  def render(assigns) do
    ~H"""
    <div class="container container-narrow account-container">
      <h1><%= gettext("Log in") %></h1>


      <p class="alert alert-info"><%= live_flash(@flash, :info) %></p>
      <p class="alert alert-error"><%= live_flash(@flash, :error) %></p>

      <.form let={f} for={:user} phx-submit="save" phx-trigger-action={@trigger_submit} action={Routes.account_path(@socket, :login)}>
        <%= label f, :email, gettext("Email") %>
        <%= text_input f, :email, value: @email %>
        <%= error_tag f, :email %>


        <%= label f, :password, gettext("Password") %>
        <%= password_input f, :plain_password, value: @password %>
        <%= error_tag f, :plain_password %>

        <%= submit gettext("Log in") %>
      </.form>

      <%= live_redirect(
        gettext("Don't have an account yet? Sign up."),
        to: Routes.register_path(LaphubWeb.Endpoint, :register_form))
      %>

      <br>

      <%= live_redirect(
        gettext("Forgot your password?"),
        to: Routes.reset_path(LaphubWeb.Endpoint, :reset_form))
      %>

    </div>
    """
  end
end
