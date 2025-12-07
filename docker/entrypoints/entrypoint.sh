#!/bin/sh
set -e

# Support for SERVICE_TYPE environment variable to switch between web and worker
# default to web if not set
SERVICE_TYPE=${SERVICE_TYPE:-web}

if [ "$SERVICE_TYPE" = "worker" ]; then
  echo "Starting Sidekiq worker..."
  bundle exec sidekiq -C config/sidekiq.yml
else
  echo "Starting Rails serve..."
  
  # release phase (optional, can be skipped if handled by Railway Release Command)
  # bundle exec rails db:chatwoot_prepare
  
  # ip lookup setup
  # bundle exec rails ip_lookup:setup
  
  # Start server
  # Using bin/rails server directly or pass through to existing rails.sh if preferred
  # For now, replicate the Procfile web command:
  bundle exec rails db:chatwoot_prepare
  bundle exec rails ip_lookup:setup && bundle exec rails server -p $PORT -b 0.0.0.0 -e $RAILS_ENV
fi
