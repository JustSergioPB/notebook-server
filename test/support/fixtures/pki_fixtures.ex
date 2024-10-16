defmodule NotebookServer.PKIFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `NotebookServer.PKI` context.
  """

  @doc """
  Generate a user_certificate.
  """
  def user_certificate_fixture(attrs \\ %{}) do
    {:ok, user_certificate} =
      attrs
      |> Enum.into(%{
        expiration_date: ~U[2024-10-12 17:42:00Z],
        certificate: "some certificate",
        status: :revoked
      })
      |> NotebookServer.PKI.create_user_certificate()

    user_certificate
  end
end
