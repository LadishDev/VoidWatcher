FROM alpine:latest

# Install necessary tools
RUN apk add --no-cache bash curl docker-cli

# Set working directory
WORKDIR /app

# Copy the script into the container
COPY voidwatcher.sh /app/voidwatcher.sh

# Set executable permissions
RUN chmod +x /app/voidwatcher.sh

# Run the script with an explicit shell
CMD ["/bin/sh", "/app/voidwatcher.sh"]
