#!/bin/bash

# Read environment variables
IFS=',' read -ra CONTAINERS <<< "$CONTAINER_NAMES"
IFS=',' read -ra WATCH_TEXTS <<< "$WATCH_TERMS"
DISCORD_WEBHOOK="$DISCORD_WEBHOOK_URL"
GOTIFY_URL="$GOTIFY_URL"
GOTIFY_TOKEN="$GOTIFY_TOKEN"

# Function to send a notification
send_alert() {
    local message="$1"

    # Send to Discord
    if [ -n "$DISCORD_WEBHOOK" ]; then
        curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"🚨 VoidWatcher Alert: $message\"}" "$DISCORD_WEBHOOK"
    fi

    # Send to Gotify
    if [ -n "$GOTIFY_URL" ] && [ -n "$GOTIFY_TOKEN" ]; then
        curl -H "X-Gotify-Key: $GOTIFY_TOKEN" -H "Content-Type: application/json" -X POST -d "{\"title\":\"VoidWatcher Alert\", \"message\":\"$message\", \"priority\":5}" "$GOTIFY_URL"
    fi
}

# Monitor logs for each container
monitor_logs() {
    local container_name="$1"
    local watch_text="$2"
    
    docker logs -f "$container_name" 2>&1 | grep --line-buffered "$watch_text" | while read -r line; do
        send_alert "Detected '$watch_text' in $container_name: $line"
    done
}

# Start monitoring in parallel
for i in "${!CONTAINERS[@]}"; do
    monitor_logs "${CONTAINERS[$i]}" "${WATCH_TEXTS[$i]}" &
done

# Keep the script running
wait
