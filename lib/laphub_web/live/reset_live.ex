defmodule LaphubWeb.ResetLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  import LaphubWeb.Gettext
  import LaphubWeb.ErrorHelpers
  alias Laphub.Account
  alias LaphubWeb.Router.Helpers, as: Routes

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
      {:noreply, assign(socket, trigger_submit: true)}
    else
      {:noreply, put_flash(socket, :error, "Invalid username or password")}
    end
    {:noreply, socket}
  end



  def render(assigns) do
    ~H"""
    <div class="container container-narrow account-container">
      <h1><%= gettext("Reset your Password") %></h1>


      <p class="alert alert-info"><%= live_flash(@flash, :info) %></p>
      <p class="alert alert-error"><%= live_flash(@flash, :error) %></p>

    </div>
    """
  end
end
