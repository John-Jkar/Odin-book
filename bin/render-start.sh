#!/usr/bin/env bash
# Start step for Render (see render.yaml).
#
# Runs migrations at boot, where the database IS reachable (unlike the build
# container), then hands off to Puma. db:prepare is a no-op when the schema is
# already up to date.
set -o errexit

bundle exec rails db:prepare

exec bundle exec puma -C config/puma.rb
