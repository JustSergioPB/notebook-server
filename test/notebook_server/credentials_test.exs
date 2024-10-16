defmodule NotebookServer.CredentialsTest do
  use NotebookServer.DataCase

  alias NotebookServer.Credentials

  describe "schemas" do
    alias NotebookServer.Credentials.Schema

    import NotebookServer.CredentialsFixtures

    @invalid_attrs %{context: nil}

    test "list_schemas/0 returns all schemas" do
      schema = schema_fixture()
      assert Credentials.list_schemas() == [schema]
    end

    test "get_schema!/1 returns the schema with given id" do
      schema = schema_fixture()
      assert Credentials.get_schema!(schema.id) == schema
    end

    test "create_schema/1 with valid data creates a schema" do
      valid_attrs = %{context: %{}}

      assert {:ok, %Schema{} = schema} = Credentials.create_schema(valid_attrs)
      assert schema.context == %{}
    end

    test "create_schema/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Credentials.create_schema(@invalid_attrs)
    end

    test "update_schema/2 with valid data updates the schema" do
      schema = schema_fixture()
      update_attrs = %{context: %{}}

      assert {:ok, %Schema{} = schema} = Credentials.update_schema(schema, update_attrs)
      assert schema.context == %{}
    end

    test "update_schema/2 with invalid data returns error changeset" do
      schema = schema_fixture()
      assert {:error, %Ecto.Changeset{}} = Credentials.update_schema(schema, @invalid_attrs)
      assert schema == Credentials.get_schema!(schema.id)
    end

    test "delete_schema/1 deletes the schema" do
      schema = schema_fixture()
      assert {:ok, %Schema{}} = Credentials.delete_schema(schema)
      assert_raise Ecto.NoResultsError, fn -> Credentials.get_schema!(schema.id) end
    end

    test "change_schema/1 returns a schema changeset" do
      schema = schema_fixture()
      assert %Ecto.Changeset{} = Credentials.change_schema(schema)
    end
  end

  describe "credentials" do
    alias NotebookServer.Credentials.Credential

    import NotebookServer.CredentialsFixtures

    @invalid_attrs %{content: nil}

    test "list_credentials/0 returns all credentials" do
      credential = credential_fixture()
      assert Credentials.list_credentials() == [credential]
    end

    test "get_credential!/1 returns the credential with given id" do
      credential = credential_fixture()
      assert Credentials.get_credential!(credential.id) == credential
    end

    test "create_credential/1 with valid data creates a credential" do
      valid_attrs = %{content: %{}}

      assert {:ok, %Credential{} = credential} = Credentials.create_credential(valid_attrs)
      assert credential.content == %{}
    end

    test "create_credential/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Credentials.create_credential(@invalid_attrs)
    end

    test "update_credential/2 with valid data updates the credential" do
      credential = credential_fixture()
      update_attrs = %{content: %{}}

      assert {:ok, %Credential{} = credential} = Credentials.update_credential(credential, update_attrs)
      assert credential.content == %{}
    end

    test "update_credential/2 with invalid data returns error changeset" do
      credential = credential_fixture()
      assert {:error, %Ecto.Changeset{}} = Credentials.update_credential(credential, @invalid_attrs)
      assert credential == Credentials.get_credential!(credential.id)
    end

    test "delete_credential/1 deletes the credential" do
      credential = credential_fixture()
      assert {:ok, %Credential{}} = Credentials.delete_credential(credential)
      assert_raise Ecto.NoResultsError, fn -> Credentials.get_credential!(credential.id) end
    end

    test "change_credential/1 returns a credential changeset" do
      credential = credential_fixture()
      assert %Ecto.Changeset{} = Credentials.change_credential(credential)
    end
  end
end
