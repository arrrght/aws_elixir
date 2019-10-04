FROM elixir:alpine
WORKDIR /app
ADD . /APP

RUN apk add git nodejs inotify-tools yarn
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix hex.info
RUN mix archive.install hex phx_new 1.4.0 --force


EXPOSE 4000
