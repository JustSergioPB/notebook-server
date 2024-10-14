defmodule NotebookServer.PKIFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `NotebookServer.PKI` context.
  """

  @doc """
  Generate a public_key.
  """
  def public_key_fixture(attrs \\ %{}) do
    {:ok, public_key} =
      attrs
      |> Enum.into(%{
        expiration_date: ~U[2024-10-12 17:42:00Z],
        key: "some key",
        status: :revoked
      })
      |> NotebookServer.PKI.create_public_key()

    public_key
  end
end
