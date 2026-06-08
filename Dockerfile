# Build stage
FROM alpine:3.19 AS builder

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache curl go gcc musl-dev git make

# Download the latest source tarball from GitHub (master branch)
RUN curl -L https://github.com/libredesk/libredesk/archive/refs/heads/master.tar.gz | tar xz --strip-components=1

# Build the binary
RUN go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o libredesk ./cmd/libredesk

# Final stage
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app
COPY --from=builder /build/libredesk /usr/local/bin/libredesk

# Create start script
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
