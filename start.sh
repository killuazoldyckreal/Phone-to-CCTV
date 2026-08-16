#!/data/data/com.termux/files/usr/bin/bash

set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$DIR/.pids"
LOG_DIR="$DIR/logs"

mkdir -p "$PID_DIR" "$LOG_DIR"

is_running() {
    local pid="$1"
    kill -0 "$pid" 2>/dev/null
}

start_process() {
    local name="$1"
    local command="$2"
    local pidfile="$PID_DIR/$name.pid"
    local logfile="$LOG_DIR/$name.log"

    if [ -f "$pidfile" ]; then
        local old_pid
        old_pid="$(cat "$pidfile")"

        if is_running "$old_pid"; then
            echo "$name is already running (PID $old_pid)"
            return
        fi

        rm -f "$pidfile"
    fi

    echo "Starting $name..."

    bash -c "$command" >> "$logfile" 2>&1 &
    local pid=$!

    echo "$pid" > "$pidfile"

    sleep 1

    if is_running "$pid"; then
        echo "$name started successfully (PID $pid)"
    else
        echo "ERROR: $name failed to start. Check:"
        echo "  $logfile"
        rm -f "$pidfile"
    fi
}

if ! command -v termux-wake-lock >/dev/null 2>&1; then
    echo "Warning: termux-wake-lock not found."
else
    termux-wake-lock
fi

echo "========================================"
echo "        PHONE TO CCTV STARTING"
echo "========================================"

start_process \
    "mediamtx" \
    "cd \"$DIR/mediamtx\" && exec ./mediamtx mediamtx.yml"

sleep 2

start_process \
    "bridge" \
    "cd \"$DIR\" && exec ./bridge.sh"

start_process \
    "viewer" \
    "cd \"$DIR/viewer\" && exec node server.js"

echo
echo "========================================"
echo "      PHONE TO CCTV IS RUNNING"
echo "========================================"
echo
echo "Run ./status.sh to check services."
echo "Run ./stop.sh to stop everything."
echo

"$DIR/status.sh"