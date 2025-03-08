FROM alpine:latest

# Install required tools
RUN apk add --no-cache bash curl docker-cli

# Set working directory
WORKDIR /app

# Copy script
COPY voidwatcher.sh ./

# Make script executable
RUN chmod +x voidwatcher.sh

# Start monitoring
CMD ["./voidwatcher.sh"]
