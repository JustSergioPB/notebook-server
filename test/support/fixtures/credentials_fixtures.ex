defmodule NotebookServer.CredentialsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `NotebookServer.Credentials` context.
  """

  @doc """
  Generate a schema.
  """
  def schema_fixture(attrs \\ %{}) do
    {:ok, schema} =
      attrs
      |> Enum.into(%{
        context: %{}
      })
      |> NotebookServer.Credentials.create_schema()

    schema
  end
end
