#!/data/data/com.termux/files/usr/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$DIR/.pids"
LOG_DIR="$DIR/logs"

MEDIA_PID="$PID_DIR/mediamtx.pid"
BRIDGE_PID="$PID_DIR/bridge.pid"
VIEWER_PID="$PID_DIR/viewer.pid"

mkdir -p "$PID_DIR"
mkdir -p "$LOG_DIR"

is_running() {
    local pid="$1"
    local expected="$2"

    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
        return 1
    fi

    local cmd
    cmd="$(ps -p "$pid" -o args= 2>/dev/null)"

    echo "$cmd" | grep -Fq "$expected"
}

start_process() {
    local name="$1"
    local pid_file="$2"
    local expected="$3"
    shift 3

    if [ -f "$pid_file" ]; then
        local pid
        pid="$(cat "$pid_file")"

        if is_running "$pid" "$expected"; then
            echo "$name is already running (PID: $pid)"
            return
        fi

        echo "Removing stale PID file for $name..."
        rm -f "$pid_file"
    fi

    echo "Starting $name..."

    "$@" &

    local pid=$!
    echo "$pid" > "$pid_file"

    sleep 1

    if is_running "$pid" "$expected"; then
        echo "$name started successfully (PID: $pid)"
    else
        echo "Failed to start $name"
        rm -f "$pid_file"
    fi
}

echo "Starting Phone-to-CCTV..."

start_process \
    "MediaMTX" \
    "$MEDIA_PID" \
    "mediamtx" \
    "$DIR/mediamtx/mediamtx" \
    "$DIR/mediamtx/mediamtx.yml" \
    >> "$LOG_DIR/mediamtx.log" 2>&1

start_process \
    "Bridge" \
    "$BRIDGE_PID" \
    "bridge.sh" \
    "$DIR/bridge.sh" \
    >> "$LOG_DIR/bridge.log" 2>&1

start_process \
    "Viewer" \
    "$VIEWER_PID" \
    "server.js" \
    node "$DIR/viewer/server.js" \
    >> "$LOG_DIR/viewer.log" 2>&1

echo
echo "Phone-to-CCTV started successfully."
echo
echo "Logs:"
echo "  MediaMTX: $LOG_DIR/mediamtx.log"
echo "  Bridge:   $LOG_DIR/bridge.log"
echo "  Viewer:   $LOG_DIR/viewer.log"
