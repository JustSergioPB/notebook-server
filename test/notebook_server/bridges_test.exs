defmodule NotebookServer.BridgesTest do
  use NotebookServer.DataCase

  alias NotebookServer.Bridges

  describe "bridges" do
    alias NotebookServer.Bridges.Bridge

    import NotebookServer.BridgesFixtures

    @invalid_attrs %{active: nil, name: nil}

    test "list_bridges/0 returns all bridges" do
      bridge = bridge_fixture()
      assert Bridges.list_bridges() == [bridge]
    end

    test "get_bridge!/1 returns the bridge with given id" do
      bridge = bridge_fixture()
      assert Bridges.get_bridge!(bridge.id) == bridge
    end

    test "create_bridge/1 with valid data creates a bridge" do
      valid_attrs = %{active: true, name: "some name"}

      assert {:ok, %Bridge{} = bridge} = Bridges.create_bridge(valid_attrs)
      assert bridge.active == true
      assert bridge.name == "some name"
    end

    test "create_bridge/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bridges.create_bridge(@invalid_attrs)
    end

    test "update_bridge/2 with valid data updates the bridge" do
      bridge = bridge_fixture()
      update_attrs = %{active: false, name: "some updated name"}

      assert {:ok, %Bridge{} = bridge} = Bridges.update_bridge(bridge, update_attrs)
      assert bridge.active == false
      assert bridge.name == "some updated name"
    end

    test "update_bridge/2 with invalid data returns error changeset" do
      bridge = bridge_fixture()
      assert {:error, %Ecto.Changeset{}} = Bridges.update_bridge(bridge, @invalid_attrs)
      assert bridge == Bridges.get_bridge!(bridge.id)
    end

    test "delete_bridge/1 deletes the bridge" do
      bridge = bridge_fixture()
      assert {:ok, %Bridge{}} = Bridges.delete_bridge(bridge)
      assert_raise Ecto.NoResultsError, fn -> Bridges.get_bridge!(bridge.id) end
    end

    test "change_bridge/1 returns a bridge changeset" do
      bridge = bridge_fixture()
      assert %Ecto.Changeset{} = Bridges.change_bridge(bridge)
    end
  end
end
