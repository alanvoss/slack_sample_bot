# Slack Sample Bot

This is a sample application for developing a Slack Bot in Plug.  Converting it to Phoenix
would be a goal for some day in the future.

## Installation

* `mix deps.get`
* `mix run --no-halt`

And then, inside slack configuration, "create a new app" for your organization.  You'll need to
fill in these two sections.  "your root endpoint" refers to the host and port on which you
just started this server.

* "Slash Commands"
  * "Create new command"
    * "Command": `/<command_name>`
    * "Request URL": your root endpoint
    * "Short Description": `<fill in something>`
    * "Usage hint": `<your interface>`
* "Interactive Components"
  * "Request URL": your root endpoint
  * "Options Load URL (for Message Menus)": leave empty
* "OAuth & Permissions"
  * "Select Permission Scopes": `Send messages as <YourBotName>`
  * "OAuth Access Token": add this to config.exs (or an env-specific `Mix.Config` file)

You can also choose to utilize an access token fetcher, also in the `config.exs` file.  It's
advised not to store any secrets, such as this, in any git repo or public dockerhub image.
