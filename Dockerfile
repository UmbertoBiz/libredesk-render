# ---- Stage 1: Extract the libredesk binary from the official image ----
FROM libredesk/libredesk:latest AS builder

# ---- Stage 2: Build a minimal Alpine-based image that includes a shell ----
FROM alpine:3.19

# Install ca-certificates (needed for HTTPS) and tzdata (for timezone support)
RUN apk add --no-cache ca-certificates tzdata

# Set the working directory
WORKDIR /app

# Copy the libredesk binary from the builder stage
COPY --from=builder /libredesk /app/libredesk

# Ensure the binary is executable
RUN chmod +x /app/libredesk

# Create a startup script that runs the install, upgrade, and then the server
RUN printf '#!/bin/sh\n\
set -e\n\
echo "Running database install (idempotent)..."\n\
/app/libredesk --install --idempotent-install --yes --config ""\n\
echo "Running database upgrades..."\n\
/app/libredesk --upgrade --yes --config ""\n\
echo "Starting Libredesk server..."\n\
exec /app/libredesk --config ""\n\
' > /start.sh && chmod +x /start.sh

# Expose the port
EXPOSE 9000

# Health check (optional)
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD /app/libredesk --version || exit 1

# Run the startup script
CMD ["/start.sh"]
