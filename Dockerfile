# syntax=docker/dockerfile:1
# Development image: the code is bind-mounted by docker-compose.yml, so edits show up without a rebuild.
# Rebuild (docker compose build) only after changing the Gemfile.

ARG RUBY_VERSION=4.0.5
FROM docker.io/library/ruby:$RUBY_VERSION-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git libssl-dev libyaml-dev pkg-config sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ARG UID=1000
ARG GID=1000
RUN groupadd --gid $GID rails && useradd rails --uid $UID --gid $GID --create-home --shell /bin/bash

WORKDIR /rails
ENV BUNDLE_PATH="/usr/local/bundle" \
    RAILS_ENV="development" \
    BINDING="0.0.0.0"

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && gem install foreman && chown -R rails:rails "$BUNDLE_PATH"

COPY --chown=rails:rails . .
RUN mkdir -p storage tmp log && chown -R rails:rails storage tmp log

USER rails
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["./bin/dev"]
