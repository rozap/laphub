defmodule LaphubWeb.Components.Inputs do
  use Phoenix.LiveComponent
  use Phoenix.HTML
  import LaphubWeb.ErrorHelpers
  import LaphubWeb.LiveUtil

  def number(assigns) do
    ~H"""
    <div phx-feedback-for={input_name(@form, @field)}>
      <%= label(@form, @field) %>
      <%= number_input(@form, @field) %>
      <%= error_tag(@form, @field) %>
    </div>
    """
  end


  attr :placeholder, :string, default: nil, required: false

  def text(assigns) do
    ~H"""
    <div phx-feedback-for={input_name(@form, @field)}>
      <%= label(@form, @field) %>
      <%= text_input(@form, @field, placeholder: @placeholder) %>
      <%= error_tag(@form, @field) %>
    </div>
    """
  end

  attr :placeholder, :string, default: nil, required: false

  def textarea(assigns) do
    ~H"""
    <div phx-feedback-for={input_name(@form, @field)}>
      <%= label(@form, @field) %>
      <%= textarea(@form, @field, placeholder: @placeholder) %>
      <%= error_tag(@form, @field) %>
    </div>
    """
  end

  attr(:grid, :boolean, default: true, required: false)
  attr(:title, :string, required: true)
  slot(:inner_block, required: true)

  def form_block(assigns) do
    ~H"""
    <fieldset>
      <h6><%= @title %></h6>

      <div class={classes([{"grid", @grid}])}>
        <%= render_slot(@inner_block) %>
      </div>
    </fieldset>
    """
  end

  attr :prompt, :string, default: nil

  def select(assigns) do
    ~H"""
    <div phx-feedback-for={input_name(@form, @field)}>
      <%= label(@form, @field) %>
      <%= select(@form, @field, @options, prompt: @prompt) %>
      <%= error_tag(@form, @field) %>
    </div>
    """
  end

  def checkbox(assigns) do
    ~H"""
    <div phx-feedback-for={input_name(@form, @field)}>
      <%= label(@form, @field) do %>
        <%= humanize(@field) %>
        <%= checkbox(@form, @field, role: "switch") %>
        <%= error_tag(@form, @field) %>
      <% end %>
    </div>
    """
  end
end
