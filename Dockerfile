# Use the official Libredesk image
FROM libredesk/libredesk:latest

# Switch to root user to fix permissions
USER root

# Fix execute permissions on the libredesk binary
RUN chmod +x /libredesk

# Set the working directory
WORKDIR /

# Create a start script
RUN printf '#!/bin/sh\n\
set -e\n\
echo "Running database install (idempotent)..."\n\
./libredesk --install --idempotent-install --yes --config ""\n\
echo "Running database upgrades..."\n\
./libredesk --upgrade --yes --config ""\n\
echo "Starting Libredesk server..."\n\
exec ./libredesk --config ""\n\
' > /start.sh && chmod +x /start.sh

# Expose the port
EXPOSE 9000

# Run the start script
CMD ["/start.sh"]
