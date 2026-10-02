#!/usr/bin/env bash
# Build step for Render (see render.yaml). Runs on every deploy.
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:prepare
