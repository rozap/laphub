defmodule LaphubWeb.Components.CommonComponents do
  use Phoenix.LiveComponent
  import LaphubWeb.LiveUtil

  def primary_button(assigns) do
    ~H"""
    <a phx-click={@click} phx-target={@myself}><%= @label %></a>
    """
  end

  def date_string(d) do
    "#{d.month}/#{d.day}/#{d.year}"
  end

  def date(assigns) do
    %{date: d} = assigns

    ~H"""
      <%= date_string(d) %>
    """
  end

  attr :fixed, :boolean, default: false
  attr :flash, :any, required: true

  def flashes(assigns) do
    ~H"""
    <% success = live_flash(@flash, :success) %>
    <%= if success do %>
      <div class={classes(["toast", "toast-success", "margin-top", {"toast-fixed", @fixed}])}>
        <%= success %>
      </div>
    <% end %>
    <% info = live_flash(@flash, :info) %>
    <%= if info do %>
      <div class={classes(["toast", "toast-primary", "margin-top", {"toast-fixed", @fixed}])}>
        <%= info %>
      </div>
    <% end %>
    <% warning = live_flash(@flash, :warning) %>
    <%= if warning do %>
      <div class={classes(["toast", "toast-warning", "margin-top", {"toast-fixed", @fixed}])}>
        <%= warning %>
      </div>
    <% end %>
    <% error = live_flash(@flash, :error) %>
    <%= if error do %>
      <div class={classes(["toast", "toast-error", "margin-top", {"toast-fixed", @fixed}])}>
        <%= error %>
      </div>
    <% end %>
    """
  end
end
