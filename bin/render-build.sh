#!/usr/bin/env bash
# Build step for Render (see render.yaml). Runs on every deploy.
#
# The build container has no access to the database, so migrations are NOT run
# here (see bin/render-start.sh). Asset precompilation still boots the app in
# production, so give it a throwaway secret instead of requiring the real
# RAILS_MASTER_KEY at build time.
set -o errexit

export SECRET_KEY_BASE_DUMMY=1

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
