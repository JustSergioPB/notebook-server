defmodule NotebookServer.PKIs do
  @moduledoc """
  The PKIs context.
  """
  import Ecto.Query, warn: false
  alias NotebookServer.Repo

  alias NotebookServer.PKIs.UserCertificate
  alias NotebookServer.PKIs.KeyPair
  alias NotebookServer.PKIs.PrivateKey

  def list_user_certificates(opts \\ []) do
    org_id = Keyword.get(opts, :org_id)

    query =
      if(org_id) do
        from(p in UserCertificate, where: p.org_id == ^org_id)
      else
        from(p in UserCertificate)
      end

    query = query |> order_by(asc: :user_id)

    Repo.all(query) |> Repo.preload(:org) |> Repo.preload(:user)
  end

  def get_user_certificate_by_user_id(user_id) do
    UserCertificate
    |> where(user_id: ^user_id)
    |> where(status: :active)
    |> Repo.one()
  end

  def change_user_certificate(%UserCertificate{} = user_certificate, attrs \\ %{}) do
    UserCertificate.changeset(user_certificate, attrs)
  end

  def create_key_pair(user_id, org_id) do
    {private_key, user_certificate} = KeyPair.generate()

    changeset = %{
      key: user_certificate,
      user_id: user_id,
      org_id: org_id,
      expiration_date: expiration_date()
    }

    %UserCertificate{}
    |> UserCertificate.changeset(changeset)
    |> Repo.insert()
    |> case do
      {:ok, user_certificate} ->
        create_private_key(org_id, user_certificate.id, private_key)
        {:ok, user_certificate}

      {:error, _changeset} ->
        {:error}
    end
  end

  def rotate_key_pair(user_id, org_id, old_user_certificate) do
    {private_key, user_certificate} = KeyPair.generate()

    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :old_user_certificate,
      UserCertificate.rotate_changeset(old_user_certificate)
    )
    |> Ecto.Multi.insert(:new_user_certificate, fn %{old_user_certificate: old_user_certificate} ->
      UserCertificate.changeset(%UserCertificate{}, %{
        key: user_certificate,
        user_id: user_id,
        org_id: org_id,
        expiration_date: expiration_date(),
        replaces_id: old_user_certificate.id
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok,
       %{old_user_certificate: old_user_certificate, new_user_certificate: new_user_certificate}} ->
        create_private_key(org_id, new_user_certificate.id, private_key)
        delete_private_key(org_id, old_user_certificate.id)
        {:ok, new_user_certificate}

      {:error, _changeset} ->
        {:error}
    end
  end

  def revoke_key_pair(user_certificate) do
    user_certificate
    |> UserCertificate.revoke_changeset(%{
      revocation_reason: "Revoked by user",
      revocation_date: DateTime.utc_now()
    })
    |> Repo.update()
    |> case do
      {:ok, user_certificate} ->
        delete_private_key(user_certificate.org_id, user_certificate.id)
        {:ok, user_certificate}

      {:error, _changeset} ->
        {:error}
    end
  end

  defp create_private_key(org_id, user_certificate_id, private_key) do
    encryptedKey = PrivateKey.encrypt(private_key)
    File.mkdir_p!("./#{org_id}/keys")
    File.write!("./#{org_id}/keys/#{user_certificate_id}.bin", encryptedKey)
  end

  defp delete_private_key(org_id, user_certificate_id) do
    File.rm!("./#{org_id}/keys/#{user_certificate_id}.bin")
  end

  defp expiration_date() do
    DateTime.utc_now() |> DateTime.add(365 * 24 * 60 * 60, :second)
  end
end
