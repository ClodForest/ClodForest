#!/bin/bash
# FILENAME: { ClodForest/bin/start.sh }
# Start ClodForest server in background

set -e

PROJECT_DIR="$HOME/git/github/ClodForest/ClodForest"
PORT=${PORT:-8080}
LOG_FILE="$PROJECT_DIR/server.log"

# Change to project directory
cd "$PROJECT_DIR"

js_files=$(find src -name '*.js' | wc -l)
if [ $js_files -gt 0 ]; then
    echo "JavaScript files found in src/! Check your workflow!"
    exit 1
fi

# Check if already running
LISTENING_PID=$(lsof -ti :$PORT 2>/dev/null || true)
if [ -n "$LISTENING_PID" ]; then
    COMMAND_LINE=$(ps -p "$LISTENING_PID" -o args= 2>/dev/null || true)
    if echo "$COMMAND_LINE" | grep -q "coffee src/app.coffee"; then
        echo "ClodForest server is already running (PID: $LISTENING_PID)"
        exit 1
    else
        echo "Error: Port $PORT is already in use by another process"
        echo "Command line: $COMMAND_LINE"
        exit 1
    fi
fi

# Start server in background
echo "Starting ClodForest server..."
nohup coffee src/app.coffee > "$LOG_FILE" 2>&1 &
SERVER_PID=$!

echo "ClodForest server started (PID: $SERVER_PID)"
