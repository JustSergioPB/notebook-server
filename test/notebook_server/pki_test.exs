defmodule NotebookServer.PKITest do
  use NotebookServer.DataCase

  alias NotebookServer.PKI

  describe "public_keys" do
    alias NotebookServer.PKI.PublicKey

    import NotebookServer.PKIFixtures

    @invalid_attrs %{status: nil, key: nil, expiration_date: nil}

    test "list_public_keys/0 returns all public_keys" do
      public_key = public_key_fixture()
      assert PKI.list_public_keys() == [public_key]
    end

    test "get_public_key!/1 returns the public_key with given id" do
      public_key = public_key_fixture()
      assert PKI.get_public_key!(public_key.id) == public_key
    end

    test "create_public_key/1 with valid data creates a public_key" do
      valid_attrs = %{status: :revoked, key: "some key", expiration_date: ~U[2024-10-12 17:42:00Z]}

      assert {:ok, %PublicKey{} = public_key} = PKI.create_public_key(valid_attrs)
      assert public_key.status == :revoked
      assert public_key.key == "some key"
      assert public_key.expiration_date == ~U[2024-10-12 17:42:00Z]
    end

    test "create_public_key/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = PKI.create_public_key(@invalid_attrs)
    end

    test "update_public_key/2 with valid data updates the public_key" do
      public_key = public_key_fixture()
      update_attrs = %{status: :active, key: "some updated key", expiration_date: ~U[2024-10-13 17:42:00Z]}

      assert {:ok, %PublicKey{} = public_key} = PKI.update_public_key(public_key, update_attrs)
      assert public_key.status == :active
      assert public_key.key == "some updated key"
      assert public_key.expiration_date == ~U[2024-10-13 17:42:00Z]
    end

    test "update_public_key/2 with invalid data returns error changeset" do
      public_key = public_key_fixture()
      assert {:error, %Ecto.Changeset{}} = PKI.update_public_key(public_key, @invalid_attrs)
      assert public_key == PKI.get_public_key!(public_key.id)
    end

    test "delete_public_key/1 deletes the public_key" do
      public_key = public_key_fixture()
      assert {:ok, %PublicKey{}} = PKI.delete_public_key(public_key)
      assert_raise Ecto.NoResultsError, fn -> PKI.get_public_key!(public_key.id) end
    end

    test "change_public_key/1 returns a public_key changeset" do
      public_key = public_key_fixture()
      assert %Ecto.Changeset{} = PKI.change_public_key(public_key)
    end
  end
end
