defmodule SlackSampleBot.Command do
  alias SlackSampleBot.Manager
  import Plug.Conn
  require Poison

  @slack_sample_bot_url "https://slack.com/api/chat.postMessage"

  def init(options) do
    options
  end

  def call(conn, _) do
    {:ok, body, _} = Plug.Conn.read_body(conn)
    params = Plug.Conn.Query.decode(body)

    {_channel, _command} = parsed_command = parse_command(params)

    manager_result = Manager.call(parsed_command)
    #send_chat_message(channel, [])
    response =  response(manager_result, parsed_command)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(response))
  end

  # optional delayed message
  defp send_chat_message(channel, stuff) do
    token = Application.get_env(:slack_sample_bot, :slack)[:token]

    if token do
      attachments =
        case stuff do
          [] -> [%{"text": "There was no stuff"}]
          stuff -> Enum.map(stuff, &(%{"text": &1}))
        end

      message_sender = fn ->
        HTTPoison.post @slack_sample_bot_url, {:form, [
          {"token", token},
          {"channel", channel},
          {"text", "*Info about stuff*"},
          {"attachments", Poison.encode!(attachments)}
        ]}
      end

      Manager.call({channel, {:delayed_message, message_sender}})
    end
  end

  defp response(result, {_, {:help}}) do
    attachments = Enum.map(result, &(%{"text" => &1}))

    %{
      "text": "Available Actions",
      "attachments": attachments
    }
  end
  
  defp response(channel_state, {_, {:state, :time}}) do
    attachments =
      channel_state.answers
      |> Enum.map(fn {id, %{answer: answer, count: count}} ->
           %{
             "text": "#{answer}",
             "callback_id": "edit_items",
             "response_type": "in_channel",
             "attachment_type": "default",
             "actions": [
               %{
                 "name": "vote",
                 "text": "Vote",
                 "type": "button",
                 "value": id,
               }
             ]
           }
         end)

    %{
      "text": "Answers",
      "attachments": attachments
    }
  end
  defp response(channel_state, {_, {:state, :tally}}) do
    attachments =
      channel_state.answers
      |> Enum.map(fn {id, %{answer: answer, count: count}} ->
           %{
             "text": "#{answer}: #{count}",
             "response_type": "in_channel",
           }
         end)

    %{
      "text": "Votes",
      "attachments": attachments
    }
  end
  defp response(acronym, {_, type}) when elem(type, 0) == :start do
    %{"text": acronym, "response_type": "in_channel"}
  end
  defp response(items, {_, type}) when elem(type, 0) in [:submit, :vote] do
    %{}
  end

  # button clicks
  defp parse_command(%{"payload" => payload}) do
    parsed_payload = payload |> Poison.decode!
    channel_id = parsed_payload["channel"]["id"]
    %{"name" => action, "value" => id} =
      parsed_payload["actions"]
      |> List.first

    action_atom = action |> String.to_atom

    {channel_id, {action_atom, id}}
  end
  # typed /queue (or whatever app name is) calls
  defp parse_command(%{"text" => text, "channel_id" => channel_id, "trigger_id" => id}) do
    submit_re = ~r/^\s*submit\s+(?<answer>.+)*$/
    cond do 
      text =~ ~r/^\s*help\s*$/ -> {channel_id, {:help}}
      text =~ ~r/^\s*start\s*$/ -> {channel_id, {:start}}
      text =~ ~r/^\s*time\s*$/ -> {channel_id, {:state, :time}}
      text =~ ~r/^\s*tally\s*$/ -> {channel_id, {:state, :tally}}
      text =~ submit_re ->
        %{"answer" => answer} = Regex.named_captures(submit_re, text)
        {channel_id, {:submit, answer, id}}
      text =~ ~r/^\s*$/ -> {channel_id, {:help}}
    end
  end
end
