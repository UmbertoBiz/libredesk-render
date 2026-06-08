#!/bin/sh
set -e

echo "Running database install (idempotent)..."
/app/libredesk --install --idempotent-install --yes

echo "Running database upgrades..."
/app/libredesk --upgrade --yes

echo "Starting Libredesk server..."
exec /app/libredesk
