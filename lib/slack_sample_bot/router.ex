defmodule SlackSampleBot.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  post "/" do
    conn
    |> SlackSampleBot.Command.call([])
  end
end
