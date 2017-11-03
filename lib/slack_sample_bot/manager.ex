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
    new_state = Map.put(state, channel, state[channel] || %{acronym: "", answers: %{}})
    do_handle_call({channel, command}, from, new_state)
  end

  defp do_handle_call({_, {:help}}, _from, state) do
    items = [
      "/#{@name} help: displays this message (privately)",
      "/#{@name} start: starts the game (can't activate during a current game)",
      "/#{@name} submit: displays this message (privately)",
    ]
    {:reply, items, state}
  end
  defp do_handle_call({channel, {:start}}, _from, state) do
    channel_state = %{acronym: "YMMV", answers: %{}}
    {:reply, channel_state[:acronym], Map.put(state, channel, channel_state)}
  end
  defp do_handle_call({channel, {:submit, answer, id}}, _from, state) do
    answers = Map.get(state[channel], :answers)
    new_answers = Map.put(answers, id, %{answer: answer, count:  0})
    {:reply, :ok, Map.put(state[channel], :answers, new_answers)}
  end
  defp do_handle_call({channel, {:vote, id}}, _from, state) do
    count = get_in(state, [channel, id, :count])
    {_, state} = get_and_update_in(state, [channel, id, :count], &{&1, &1 + 1})
    {:reply, :ok, state}
  end
  defp do_handle_call({channel, {:state, _}}, _from, state) do
    {:reply, state[channel], state}
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
