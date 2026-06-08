# ---- Build stage ----
FROM golang:1.25-alpine AS builder

# Install git for fetching dependencies
RUN apk add --no-cache git

# Set the working directory
WORKDIR /app

# Clone the repository
RUN git clone https://github.com/abhinavxd/libredesk.git .

# Download dependencies and build the binary
RUN go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o libredesk ./cmd/libredesk

# ---- Runtime stage ----
FROM alpine:3.19

# Install ca-certificates for HTTPS and tzdata for timezone support
RUN apk add --no-cache ca-certificates tzdata

# Set the working directory
WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/libredesk /app/libredesk

# Ensure the binary is executable
RUN chmod +x /app/libredesk

# Copy a custom entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose the port
EXPOSE 9000

# Use the entrypoint script to run migrations and start the server
ENTRYPOINT ["/entrypoint.sh"]
