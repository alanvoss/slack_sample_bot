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
    # send_chat_message(channel, [])
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

  defp response(result, _) when length(result) == 0 do
    %{
      "text": "List is empty",
    }
  end
  defp response(result, {_, {:help}}) do
    attachments = Enum.map(result, &(%{"text" => &1}))

    %{
      "text": "Available Actions",
      "attachments": attachments
    }
  end
  defp response(items, {_, type}) when elem(type, 0) in [:edit, :remove] do
    attachments =
      items 
      |> Enum.with_index()
      |> Enum.map(fn {%{"id" => id, "item" => item}, index} ->
           %{
             "text": "#{index + 1}. #{item}",
             "callback_id": "edit_items",
             "attachment_type": "default",
             "actions": [
               %{
                 "name": "remove",
                 "text": "Remove",
                 "type": "button",
                 "value": id,
                 "confirm": %{
                   "title": "Are you sure?",
                   "text": "This will remove the item from the queue and is irreversible.",
                   "ok_text": "Yes",
                   "dismiss_text": "No"
                 }
               }
             ]
           }
         end)

    %{
      "text": "Edit the queue",
      "attachments": attachments
    }
  end
  defp response(items, {_, type}) when elem(type, 0) == :push do
    attachments =
      items
      |> Enum.with_index()
      |> Enum.map(fn {queue, index} -> %{"text" => "#{index + 1}. #{queue}"} end)

    %{
      "text": "Current List",
      "attachments": attachments
    }
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
    cond do
      text =~ ~r/^\s*help\s*$/ -> {channel_id, {:help}}
      text =~ ~r/^\s*edit\s*$/ -> {channel_id, {:edit}}
      text =~ ~r/^\s*$/ -> {channel_id, {:help}}
      true -> {channel_id, {:push, id, text}}
    end
  end
end
