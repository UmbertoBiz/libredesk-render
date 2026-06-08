FROM libredesk/libredesk:latest

# Copy a start script into the container
RUN printf '#!/bin/sh\n\
set -e\n\
echo "Running database install (idempotent)..."\n\
libredesk --install --idempotent-install --yes --config ""\n\
echo "Running database upgrades..."\n\
libredesk --upgrade --yes --config ""\n\
echo "Starting Libredesk server..."\n\
exec libredesk --config ""\n\
' > /start.sh && chmod +x /start.sh

# Expose the port Render expects
EXPOSE 9000

# Make sure the service stays healthy
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD libredesk --version || exit 1

# This is what Render will run
CMD ["/start.sh"]
