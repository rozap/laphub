defmodule LaphubWeb.RegisterLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  import LaphubWeb.Gettext
  import LaphubWeb.ErrorHelpers
  alias LaphubWeb.Router.Helpers, as: Routes
  alias Laphub.Account

  def mount(_params, _, socket) do
    socket = assign(socket, changeset: Account.new_user(%{}), trigger_submit: false)
    {:ok, socket}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    cset =
      case Account.new_user(params) do
        %{action: nil} = cset -> Map.put(cset, :action, socket.assigns.changeset.action)
        cset -> cset
      end

    {:noreply, assign(socket, :changeset, cset)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    cset = Account.new_user(params)

    socket =
      case Account.create_user(params) do
        {:ok, _} ->
          assign(socket, changeset: cset, trigger_submit: true)

        {:error, %Ecto.Changeset{} = cset} ->
          assign(socket, changeset: cset)
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container container-narrow account-container">
      <h1><%= gettext("Sign up") %></h1>

      <.form
        let={f}
        for={@changeset}
        phx-trigger-action={@trigger_submit}
        phx-change="validate"
        phx-submit="save"
        action={Routes.account_path(@socket, :login)}>

        <%= label f, :email, gettext("Email") %>
        <%= text_input f, :email %>
        <%= error_tag f, :email %>

        <%= label f, :display_name, gettext("Display name") %>
        <%= text_input f, :display_name %>
        <%= error_tag f, :display_name %>

        <%= label f, :password, gettext("Password") %>
        <%= password_input f, :plain_password, value: input_value(f, :plain_password) %>
        <%= error_tag f, :plain_password %>

        <%= submit gettext("Sign up") %>
      </.form>

      <br>
      <%= live_redirect(
        gettext("Already have an account? Log in."),
        to: Routes.login_path(LaphubWeb.Endpoint, :login_form))
      %>

    </div>

    """
  end
end
