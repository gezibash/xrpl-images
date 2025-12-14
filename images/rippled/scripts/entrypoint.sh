#!/bin/bash
set -e

# rippled Docker entrypoint script
# Handles configuration, signal trapping, and process management

# Default paths
RIPPLED_CONF=${RIPPLED_CONF:-/etc/rippled/rippled.cfg}
RIPPLED_BIN=${RIPPLED_BIN:-/opt/ripple/bin/rippled}

# Signal handling for graceful shutdown
shutdown() {
    echo "Received shutdown signal, stopping rippled gracefully..."
    if [ -n "$RIPPLED_PID" ]; then
        kill -TERM "$RIPPLED_PID" 2>/dev/null || true
        wait "$RIPPLED_PID" 2>/dev/null || true
    fi
    exit 0
}

trap shutdown SIGTERM SIGINT SIGQUIT

# Print version info
echo "Starting rippled..."
"$RIPPLED_BIN" --version || true

# If no arguments provided, use defaults
if [ "$#" -eq 0 ]; then
    set -- "$RIPPLED_BIN" --conf "$RIPPLED_CONF"
fi

# If first argument is 'rippled', prepend the full path
if [ "$1" = "rippled" ]; then
    shift
    set -- "$RIPPLED_BIN" "$@"
fi

# Execute rippled in foreground
echo "Executing: $@"
exec "$@" &
RIPPLED_PID=$!

# Wait for rippled to exit
wait "$RIPPLED_PID"
