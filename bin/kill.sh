#!/bin/bash
# FILENAME: { ClodForest/bin/kill.sh }
# Stop ClodForest server safely

set -e

PROJECT_DIR="$HOME/git/github/ClodForest/ClodForest"
PID_FILE="$PROJECT_DIR/.pid"

# Change to project directory
cd "$PROJECT_DIR"

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    echo "No PID file found - server may not be running"
    exit 0
fi

# Read PID
SERVER_PID=$(cat "$PID_FILE")

# Check if process is actually running
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Process $SERVER_PID is not running - cleaning up PID file"
    rm "$PID_FILE"
    exit 0
fi

# Verify this is actually our ClodForest process by checking the command line
if ps -p "$SERVER_PID" -o args= | grep -q "coffee src/app.coffee"; then
    echo "Stopping ClodForest server (PID: $SERVER_PID)..."
    kill "$SERVER_PID"

    # Wait for process to stop
    for i in {1..10}; do
        if ! kill -0 "$SERVER_PID" 2>/dev/null; then
            break
        fi
        sleep 1
    done

    # Force kill if still running
    if kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "Process didn't stop gracefully, force killing..."
        kill -9 "$SERVER_PID"
    fi

    rm "$PID_FILE"
    echo "ClodForest server stopped"
else
    echo "Warning: PID $SERVER_PID doesn't appear to be ClodForest server"
    echo "Command line: $(ps -p $SERVER_PID -o args= 2>/dev/null || echo 'Process not found')"
    echo "Not killing process for safety"
    exit 1
fi
