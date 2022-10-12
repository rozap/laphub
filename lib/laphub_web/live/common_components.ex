defmodule LaphubWeb.Components.CommonComponents do
  use Phoenix.LiveComponent

  def primary_button(assigns) do
    ~H"""
    <a phx-click={@click}><%= @label %></a>
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
end
