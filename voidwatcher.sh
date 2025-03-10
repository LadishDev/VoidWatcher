#!/bin/sh

# Read environment variables
CONTAINER_NAMES=${CONTAINER_NAMES:-""}
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL:-""}
GOTIFY_URL=${GOTIFY_URL:-""}
GOTIFY_TOKEN=${GOTIFY_TOKEN:-""}

# Append /message to GOTIFY_URL if it is set
if [ -n "$GOTIFY_URL" ]; then
  GOTIFY_URL="${GOTIFY_URL%/}/message"  # Ensure no double slashes
fi

# Debugging: Print all environment variables
echo "Environment Variables:"
echo "CONTAINER_NAMES: $CONTAINER_NAMES"
echo "DISCORD_WEBHOOK_URL: $DISCORD_WEBHOOK_URL"
echo "GOTIFY_URL: $GOTIFY_URL"
echo "GOTIFY_TOKEN: $GOTIFY_TOKEN"

# Ensure at least one container is defined
if [ -z "$CONTAINER_NAMES" ]; then
  echo "❌ No containers specified. Set CONTAINER_NAMES environment variable."
  exit 1
fi

# Normalize container names: Replace hyphens with underscores
NORMALIZED_CONTAINER_NAMES=$(echo "$CONTAINER_NAMES" | tr '-' '_')

# Split container names into an array
CONTAINERS=$(echo "$NORMALIZED_CONTAINER_NAMES" | tr ',' ' ')

# Function to process logs for a container
watch_logs() {
  local CONTAINER="$1"
  local TERMS_VAR="$2"  # Name of the environment variable for terms

  # Dynamically fetch the terms from the environment variable
  TERMS_LIST=$(eval echo \$$TERMS_VAR)

  if [ -z "$TERMS_LIST" ]; then
    echo "⚠️ No watch terms defined for container: $CONTAINER"
    return
  fi

  # Debugging: Print container and terms
  echo "👀 Watching logs for container: $CONTAINER (Terms: $TERMS_LIST)"

  # Split terms into an array
  TERMS=$(echo "$TERMS_LIST" | tr ',' ' ')

  # Convert terms to regex format: "error|warning|fail"
  TERMS_REGEX=$(echo "$TERMS" | tr ' ' '|')

  # Stream logs and check for matches
  docker logs -f "$CONTAINER" 2>&1 | awk -v container="$CONTAINER" -v discord="$DISCORD_WEBHOOK_URL" -v gotify="$GOTIFY_URL" -v token="$GOTIFY_TOKEN" -v terms="$TERMS_REGEX" '
  BEGIN { 
    # Pre-compile terms regex
    split(terms, term_array, "|")
    term_pattern = "(" term_array[1]
    for (i = 2; i <= length(term_array); i++) {
      term_pattern = term_pattern "|" term_array[i]
    }
    term_pattern = term_pattern ")"
  }
  {
    if ($0 ~ term_pattern) {
      print "🚨 Found match in " container ": " $0

      # Send notification to Discord
      if (discord != "") {
        message = "🚨 Found in " container " log: " $0
        gsub(/"/, "\\\"", message)
        cmd = "curl -s -X POST -H \"Content-Type: application/json\" -d \"{\\\"content\\\": \\\"" message "\\\"}\" " discord
        system(cmd)
      }

      # Send notification to Gotify
      if (gotify != "" && token != "") {
        message = $0
        gsub(/"/, "\\\"", message)
        cmd = "curl -s -X POST -H \"Content-Type: application/json\" -d \"{\\\"title\\\": \\\"Log Alert: " container "\\\", \\\"message\\\": \\\"" message "\\\"}\" " gotify "?token=" token
        system(cmd)
      }
    }
  }'
}

# Start watching logs for each container
for CONTAINER in $CONTAINERS; do
  # Normalize the container name for the TERMS_VAR
  NORMALIZED_CONTAINER=$(echo "$CONTAINER" | tr '-' '_')
  CONTAINER_TERMS_VAR="${NORMALIZED_CONTAINER}_TERMS"
  watch_logs "$CONTAINER" "$CONTAINER_TERMS_VAR" &
done

# Keep script running
wait