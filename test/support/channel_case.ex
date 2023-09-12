defmodule LaphubWeb.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      import Phoenix.ChannelTest
      import LaphubWeb.ChannelCase

      # The default endpoint for testing
      @endpoint LaphubWeb.Endpoint
    end
  end

  setup tags do
    Laphub.DataCase.setup_sandbox(tags)
    :ok
  end
end
