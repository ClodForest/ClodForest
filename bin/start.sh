#!/bin/bash
# FILENAME: { ClodForest/bin/start.sh }
# Start ClodForest server in background

set -e

PROJECT_DIR="/mnt/nvme0n1p4/git/github/ClodForest/ClodForest"
PID_FILE="$PROJECT_DIR/.pid"
LOG_FILE="$PROJECT_DIR/server.log"

# Change to project directory
cd "$PROJECT_DIR"

# Check if already running
if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "ClodForest server is already running (PID: $(cat $PID_FILE))"
    exit 1
fi

# Start server in background
echo "Starting ClodForest server..."
nohup coffee src/app.coffee > "$LOG_FILE" 2>&1 &
SERVER_PID=$!

# Save PID
echo $SERVER_PID > "$PID_FILE"

echo "ClodForest server started in background (PID: $SERVER_PID)"
echo "Logs: tail -f $LOG_FILE"
echo "Stop with: npm run kill"
