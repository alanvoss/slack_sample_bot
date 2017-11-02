defmodule SlackSampleBot.Manager do
  use GenServer

  @name Application.get_env(:slack_sample_bot, :slack)[:name] 
  @timeout 30

  def start_link do
    GenServer.start_link(__MODULE__, nil, [name: :manager])
  end

  def init(_) do
    {:ok, %{}}
  end

  def call({channel, action}) do
    GenServer.call(:manager, {channel, action})
  end

  # placeholder in case you'd like to do something with every result
  # (persist data in redis, for example)
  def handle_call({channel, command}, from, state) do
    do_handle_call({channel, command}, from, state)
  end

  defp do_handle_call({_, {:help}}, _from, state) do
    items = [
      "/#{@name} help: displays this message (privately)",
    ]
    {:reply, items, state}
  end
  defp do_handle_call({channel, {:push, id, item}}, _from, state) do
    queue = List.wrap(state[channel])
    new_queue = queue ++ [%{"id" => id, "item" => item}]
    items = Enum.map(new_queue, &(&1["item"]))
    {:reply, items, Map.put(state, channel, new_queue)}
  end
  defp do_handle_call({channel, {:edit}}, _from, state) do
    queue = List.wrap(state[channel])
    {:reply, queue, state}
  end
  defp do_handle_call({channel, {:remove, id}}, _from, state) do
    queue = List.wrap(state[channel])
    new_queue =
      case Enum.find_index(queue, &(&1["id"] == id)) do
        nil -> queue
        index -> List.delete_at(queue, index)
      end
    {:reply, new_queue, Map.put(state, channel, new_queue)}
  end
  defp do_handle_call({channel, {:delayed_message, message_sender}}, from, state) do
    case state[channel]["delayed_job_ref"] do
      nil ->
        sender_ref = Process.send_after(self(), {:delayed_response, channel, message_sender}, @timeout * 1000)
        {:reply, :ok, put_in(state, [channel, "delayed_job_ref"], sender_ref)}
      sender_ref ->
        Process.cancel_timer(sender_ref)
        do_handle_call({channel, {:delayed_message, message_sender}}, from, put_in(state, [channel, "delayed_job_ref"], nil))
    end
  end

  def handle_info({:delayed_response, channel, message_sender}, state) do
    message_sender.()
    {:noreply, put_in(state, [channel, "delayed_job_ref"], nil)}
  end
end
