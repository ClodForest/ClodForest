#!/bin/bash
# FILENAME: { ClodForest/bin/kill.sh }
# Stop ClodForest server safely

set -e

PROJECT_DIR="$HOME/git/github/ClodForest/ClodForest"
PORT=${PORT:-8080}

# Change to project directory
cd "$PROJECT_DIR"

# Check what's listening on the configured port
LISTENING_PID=$(lsof -ti :$PORT 2>/dev/null || true)

if [ -z "$LISTENING_PID" ]; then
    echo "Nothing listening on port $PORT - server not running"
    exit 0
fi

# Check if it's our ClodForest process
COMMAND_LINE=$(ps -p "$LISTENING_PID" -o args= 2>/dev/null || true)

if [ -z "$COMMAND_LINE" ]; then
    echo "Process $LISTENING_PID not found"
    exit 0
fi

if echo "$COMMAND_LINE" | grep -q "coffee src/app.coffee"; then
    echo "Stopping ClodForest server (PID: $LISTENING_PID)..."
    kill "$LISTENING_PID"

    # Wait for process to stop
    for i in {1..10}; do
        if ! kill -0 "$LISTENING_PID" 2>/dev/null; then
            break
        fi
        sleep 1
    done

    # Force kill if still running
    if kill -0 "$LISTENING_PID" 2>/dev/null; then
        echo "Process didn't stop gracefully, force killing..."
        kill -9 "$LISTENING_PID"
    fi

    echo "ClodForest server stopped"
else
    echo "Error: Something else is listening on port $PORT"
    echo "Command line: $COMMAND_LINE"
    echo "Not killing process for safety"
    exit 1
fi
