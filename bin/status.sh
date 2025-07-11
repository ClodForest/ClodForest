#!/bin/bash
# FILENAME: { ClodForest/bin/status.sh }
# Check ClodForest server status

PROJECT_DIR="$HOME/git/github/ClodForest/ClodForest"
PORT=${PORT:-8080}
LOG_FILE="$PROJECT_DIR/server.log"

# Change to project directory
cd "$PROJECT_DIR"

# Check what's listening on the configured port
LISTENING_PID=$(lsof -ti :$PORT 2>/dev/null || true)

if [ -z "$LISTENING_PID" ]; then
    echo "ClodForest server is not running (nothing listening on port $PORT)"
    exit 1
fi

# Check if it's our ClodForest process
COMMAND_LINE=$(ps -p "$LISTENING_PID" -o args= 2>/dev/null || true)

if [ -z "$COMMAND_LINE" ]; then
    echo "ClodForest server is not running (process $LISTENING_PID not found)"
    exit 1
fi

if echo "$COMMAND_LINE" | grep -q "coffee src/app.coffee"; then
    echo "ClodForest server is running (PID: $LISTENING_PID)"
    echo "Started: $(ps -p $LISTENING_PID -o lstart= 2>/dev/null)"
    
    # Check health endpoint
    HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/api/health" 2>/dev/null || echo "000")
    
    if [ "$HEALTH_STATUS" = "200" ]; then
        echo "Health check: OK"
    else
        echo "Health check: FAILED (HTTP $HEALTH_STATUS)"
    fi
    
    exit 0
else
    echo "Warning: Something else is listening on port $PORT"
    echo "Command line: $COMMAND_LINE"
    exit 1
fi
