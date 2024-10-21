defmodule NotebookServer.PKITest do
  use NotebookServer.DataCase

  alias NotebookServer.PKI

  describe "user_certificates" do
    alias NotebookServer.PKI.UserCertificate

    import NotebookServer.PKIFixtures

    @invalid_attrs %{status: nil, certificate: nil, expiration_date: nil}

    test "list_user_certificates/0 returns all user_certificates" do
      user_certificate = user_certificate_fixture()
      assert PKI.list_user_certificates() == [user_certificate]
    end

    test "get_user_certificate!/1 returns the user_certificate with given id" do
      user_certificate = user_certificate_fixture()
      assert PKI.get_user_certificate!(user_certificate.id) == user_certificate
    end

    test "create_user_certificate/1 with valid data creates a user_certificate" do
      valid_attrs = %{status: :revoked, certificate: "some certificate", expiration_date: ~U[2024-10-12 17:42:00Z]}

      assert {:ok, %UserCertificate{} = user_certificate} = PKI.create_user_certificate(valid_attrs)
      assert user_certificate.status == :revoked
      assert user_certificate.certificate == "some certificate"
      assert user_certificate.expiration_date == ~U[2024-10-12 17:42:00Z]
    end

    test "create_user_certificate/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = PKI.create_user_certificate(@invalid_attrs)
    end

    test "update_user_certificate/2 with valid data updates the user_certificate" do
      user_certificate = user_certificate_fixture()
      update_attrs = %{status: :active, certificate: "some updated certificate", expiration_date: ~U[2024-10-13 17:42:00Z]}

      assert {:ok, %UserCertificate{} = user_certificate} = PKI.update_user_certificate(user_certificate, update_attrs)
      assert user_certificate.status == :active
      assert user_certificate.certificate == "some updated certificate"
      assert user_certificate.expiration_date == ~U[2024-10-13 17:42:00Z]
    end

    test "update_user_certificate/2 with invalid data returns error changeset" do
      user_certificate = user_certificate_fixture()
      assert {:error, %Ecto.Changeset{}} = PKI.update_user_certificate(user_certificate, @invalid_attrs)
      assert user_certificate == PKI.get_user_certificate!(user_certificate.id)
    end

    test "delete_user_certificate/1 deletes the user_certificate" do
      user_certificate = user_certificate_fixture()
      assert {:ok, %UserCertificate{}} = PKI.delete_user_certificate(user_certificate)
      assert_raise Ecto.NoResultsError, fn -> PKI.get_user_certificate!(user_certificate.id) end
    end

    test "change_user_certificate/1 returns a user_certificate changeset" do
      user_certificate = user_certificate_fixture()
      assert %Ecto.Changeset{} = PKI.change_user_certificate(user_certificate)
    end
  end
end
