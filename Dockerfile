FROM elixir:1.5.2

ENV HOME=/home/elixir MIX_ENV=prod
RUN groupadd -r elixir && useradd -r -g elixir --create-home elixir

RUN apt-get update
RUN apt-get -y install unzip python2.7 python2.7-dev

RUN mkdir -p $HOME/slack_sample_bot
WORKDIR $HOME/slack_sample_bot
RUN mix local.hex --force
RUN mix local.rebar --force

RUN chown -R elixir:elixir $HOME

COPY . $HOME/slack_sample_bot
RUN chown -R elixir:elixir $HOME

USER elixir
EXPOSE 4000

RUN mix deps.get
ENTRYPOINT mix run --no-halt
