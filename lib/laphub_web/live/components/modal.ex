defmodule LaphubWeb.Components.Modal do
  use Phoenix.LiveComponent

  def handle_event("open", _, socket) do
    {:noreply, assign(socket, :open, true)}
  end
  def handle_event("close", _, socket) do
    {:noreply, assign(socket, :open, false)}
  end

  attr :open, :boolean, default: false
  attr :title, :string, required: true
  attr :button, :string, required: true
  slot :footer

  def render(assigns) do
    ~H"""
    <div>
      <button class="btn btn-primary" phx-click="open" phx-target={@myself}>
        <%= @button %>
      </button>
      <dialog :if={@open} open>
        <article>
          <header>
            <a aria-label="Close" class="close" phx-click="close" phx-target={@myself}></a>
            <%= @title %>
          </header>

          <%= render_slot(@inner_block) %>

          <footer>
          <%= render_slot(@footer) %>
          </footer>
        </article>
      </dialog>
    </div>
    """
  end
end
