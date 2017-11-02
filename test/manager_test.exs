defmodule SlackSampleBot.ManagerTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, %{channel: make_ref()}}
  end

  describe "#help" do
    test "returns help items", %{channel: channel} do
      name = Application.get_env(:slack_sample_bot, :slack)[:name]
      help_items = SlackSampleBot.Manager.call({channel, {:help}})
      assert Enum.all?(help_items, &(String.starts_with?(&1, "/#{name}")))
    end
  end

  describe "#push" do
    test "adds an item", %{channel: channel} do
      item = "alan"
      list = SlackSampleBot.Manager.call({channel, {:edit}})
      assert length(list) == 0
      add_item(channel, item)
      list = SlackSampleBot.Manager.call({channel, {:edit}})
      assert length(list) == 1
      assert [%{"item" => ^item}] = list
    end
  end

  describe "#edit" do
    test "returns the current list, each with an id and item", %{channel: channel} do
      items = ["medicine", "broth"]
      Enum.each(items, &(add_item(channel, &1)))
      list = SlackSampleBot.Manager.call({channel, {:edit}})
      assert length(list) == length(items)
      assert Enum.all?(Enum.zip(items, list), fn {item, %{"id" => _, "item" => list_item}} -> item == list_item end)
    end

  end

  describe "#remove" do
    test "removes an item from the list", %{channel: channel} do
      items = ["do", "re", "mi", "fa"]
      Enum.each(items, &(add_item(channel, &1)))
      list = SlackSampleBot.Manager.call({channel, {:edit}})
      assert length(list) == length(items)
      [%{"id" => id} | _] = list
      SlackSampleBot.Manager.call({channel, {:remove, id}})
      list = SlackSampleBot.Manager.call({channel, {:edit}})
      assert length(list) == length(items) - 1
    end
  end

  defp add_item(channel, item) do
    SlackSampleBot.Manager.call({channel, {:push, make_ref(), item}})
  end
end
