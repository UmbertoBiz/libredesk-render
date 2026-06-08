# Use the official image with a specific version tag
FROM libredesk/libredesk:v2.2.1

# Copy a start script into the container
RUN printf '#!/bin/sh\n\
set -e\n\
echo "Running database install (idempotent)..."\n\
/app/libredesk --install --idempotent-install --yes --config ""\n\
echo "Running database upgrades..."\n\
/app/libredesk --upgrade --yes --config ""\n\
echo "Starting Libredesk server..."\n\
exec /app/libredesk --config ""\n\
' > /start.sh && chmod +x /start.sh

# Expose the port Render expects
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD /app/libredesk --version || exit 1

# This is what Render will run
CMD ["/start.sh"]
