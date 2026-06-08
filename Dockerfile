# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Install git
RUN apk add --no-cache git

# Clone the latest Libredesk source
RUN git clone https://github.com/libredesk/libredesk.git . && \
    git checkout $(git describe --tags $(git rev-list --tags --max-count=1))

# Download dependencies and build the binary
RUN go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o libredesk ./cmd/libredesk

# Final stage – small Alpine image
FROM alpine:3.19

# Install ca-certificates for HTTPS (required for S3/R2)
RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /build/libredesk /usr/local/bin/libredesk

# Create a simple start script
RUN printf '#!/bin/sh\n\
set -e\n\
echo "Running database install (idempotent)..."\n\
libredesk --install --idempotent-install --yes --config ""\n\
echo "Running database upgrades..."\n\
libredesk --upgrade --yes --config ""\n\
echo "Starting Libredesk server..."\n\
exec libredesk --config ""\n\
' > /start.sh && chmod +x /start.sh

EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD libredesk --version || exit 1

CMD ["/start.sh"]
