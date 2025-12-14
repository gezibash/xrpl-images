#!/bin/bash
set -e

# Clio Docker entrypoint script
# Handles configuration, signal trapping, and process management

# Default paths
CLIO_CONF=${CLIO_CONF:-/etc/clio/config.json}
CLIO_BIN=${CLIO_BIN:-/opt/clio/bin/clio_server}

# Signal handling for graceful shutdown
shutdown() {
    echo "Received shutdown signal, stopping clio gracefully..."
    if [ -n "$CLIO_PID" ]; then
        kill -TERM "$CLIO_PID" 2>/dev/null || true
        wait "$CLIO_PID" 2>/dev/null || true
    fi
    exit 0
}

trap shutdown SIGTERM SIGINT SIGQUIT

# Print version info
echo "Starting clio..."
"$CLIO_BIN" --version 2>/dev/null || true

# If no arguments provided, use defaults
if [ "$#" -eq 0 ]; then
    set -- "$CLIO_BIN" --conf "$CLIO_CONF"
fi

# If first argument is 'clio_server', prepend the full path
if [ "$1" = "clio_server" ]; then
    shift
    set -- "$CLIO_BIN" "$@"
fi

# Execute clio in foreground
echo "Executing: $@"
exec "$@" &
CLIO_PID=$!

# Wait for clio to exit
wait "$CLIO_PID"
