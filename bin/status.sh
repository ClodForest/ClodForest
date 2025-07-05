#!/bin/bash
# FILENAME: { ClodForest/bin/status.sh }
# Check ClodForest server status

PROJECT_DIR="/mnt/nvme0n1p4/git/github/ClodForest/ClodForest"
PID_FILE="$PROJECT_DIR/.pid"
LOG_FILE="$PROJECT_DIR/server.log"

# Change to project directory
cd "$PROJECT_DIR"

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    echo "ClodForest server is not running (no PID file)"
    exit 1
fi

# Read PID
SERVER_PID=$(cat "$PID_FILE")

# Check if process is actually running
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "ClodForest server is not running (stale PID file)"
    exit 1
fi

# Verify this is actually our ClodForest process
if ps -p "$SERVER_PID" -o args= | grep -q "coffee src/app.coffee"; then
    echo "ClodForest server is running (PID: $SERVER_PID)"
    echo "Started: $(ps -p $SERVER_PID -o lstart= 2>/dev/null)"
    echo "Log file: $LOG_FILE"
    echo "View logs: tail -f $LOG_FILE"
    exit 0
else
    echo "Warning: PID $SERVER_PID exists but doesn't appear to be ClodForest server"
    echo "Command line: $(ps -p $SERVER_PID -o args= 2>/dev/null || echo 'Process not found')"
    exit 1
fi
