# VoidWatcher

Get Started 

```ymal
services:
  voidwatcher:
    image: ghcr.io/ladishdev/voidwatcher:latest   # Image from GHCR
    container_name: voidwatcher
    environment:
      - CONTAINER_NAMES=my_container_1,my_container_2    # Container names to watch
      - WATCH_TERMS=error,critical failure                # Terms to watch in logs
      - DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/your_webhook_url  # Discord Webhook
      - GOTIFY_URL=http://your-gotify-url/message        # Gotify URL
      - GOTIFY_TOKEN=your_gotify_token                   # Gotify Token
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock   # Mount Docker socket
    restart: always   # Ensure the container restarts if it fails
```
