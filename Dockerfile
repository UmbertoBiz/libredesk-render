# ==============================
# Stage 1: Fetch the pre-built binary
# ==============================
FROM alpine:3.19 AS fetcher

WORKDIR /download

# Install only the tools needed to download and verify the binary
RUN apk add --no-cache curl

# Find the URL of the latest stable release asset (linux_amd64)
# The binary is named "libredesk" (no version suffix)
RUN LATEST_URL=$(curl -s https://api.github.com/repos/abhinavxd/libredesk/releases/latest | grep -oP '"browser_download_url": "\K[^"]+' | grep linux_amd64) && \
    curl -L -o libredesk "$LATEST_URL" && \
    chmod +x libredesk

# ==============================
# Stage 2: Minimal runtime image
# ==============================
FROM alpine:3.19

# Runtime dependencies (TLS, timezone)
RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Copy the binary from the fetcher stage
COPY --from=fetcher /download/libredesk /app/libredesk

# Idempotent startup script
RUN printf '#!/bin/sh\n\
set -e\n\
echo "Running database install (idempotent)..."\n\
./libredesk --install --idempotent-install --yes --config ""\n\
echo "Running database upgrades..."\n\
./libredesk --upgrade --yes --config ""\n\
echo "Starting Libredesk server..."\n\
exec ./libredesk --config ""\n\
' > /start.sh && chmod +x /start.sh

# Container port
EXPOSE 9000

# Health check (optional but recommended)
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD ./libredesk --version || exit 1

# The start script handles install → upgrade → run
CMD ["/start.sh"]
