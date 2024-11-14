defmodule NotebookServer.BridgesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `NotebookServer.Bridges` context.
  """

  @doc """
  Generate a bridge.
  """
  def bridge_fixture(attrs \\ %{}) do
    {:ok, bridge} =
      attrs
      |> Enum.into(%{
        active: true,
        name: "some name"
      })
      |> NotebookServer.Bridges.create_bridge()

    bridge
  end
end
