defmodule NotebookServer.PKIs do
  @moduledoc """
  The PKIs context.
  """
  import Ecto.Query, warn: false
  alias NotebookServer.Repo

  alias NotebookServer.PKIs.PublicKey
  alias NotebookServer.PKIs.KeyPair
  alias NotebookServer.PKIs.PrivateKey

  def get_public_key_by_user_id(user_id) do
    PublicKey
    |> where(user_id: ^user_id)
    |> where(status: :active)
    |> Repo.one()
  end

  def create_key_pair(user_id, org_id) do
    {private_key, public_key} = KeyPair.generate()

    changeset = %{
      key: public_key,
      user_id: user_id,
      org_id: org_id,
      expiration_date: expiration_date()
    }

    %PublicKey{}
    |> PublicKey.changeset(changeset)
    |> Repo.insert()
    |> case do
      {:ok, public_key} ->
        create_private_key(org_id, public_key.id, private_key)
        {:ok, public_key}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def rotate_key_pair(user_id, org_id, old_public_key) do
    {private_key, public_key} = KeyPair.generate()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:old_public_key, PublicKey.rotate_changeset(old_public_key))
    |> Ecto.Multi.insert(:new_public_key, fn %{old_public_key: old_public_key} ->
      PublicKey.changeset(%PublicKey{}, %{
        key: public_key,
        user_id: user_id,
        org_id: org_id,
        expiration_date: expiration_date(),
        replaces: old_public_key.id
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{old_public_key: old_public_key, new_public_key: new_public_key}} ->
        create_private_key(org_id, new_public_key.id, private_key)
        delete_private_key(org_id, old_public_key.id)
        {:ok, new_public_key}

      {:error, _changeset} ->
        {:error}
    end
  end

  def revoke_key_pair(public_key) do
    public_key
    |> PublicKey.revoke_changeset()
    |> Repo.update()
    |> case do
      {:ok, public_key} ->
        delete_private_key(public_key.org_id, public_key.id)
        {:ok, public_key}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp create_private_key(org_id, public_key_id, private_key) do
    encryptedKey = PrivateKey.encrypt(private_key)
    File.mkdir_p!("./#{org_id}/keys")
    File.write!("./#{org_id}/keys/#{public_key_id}.bin", encryptedKey)
  end

  defp delete_private_key(org_id, public_key_id) do
    File.rm!("./#{org_id}/keys/#{public_key_id}.bin")
  end

  defp expiration_date() do
    DateTime.utc_now() |> DateTime.add(365 * 24 * 60 * 60, :second)
  end
end
