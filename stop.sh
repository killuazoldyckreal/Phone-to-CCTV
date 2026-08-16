#!/data/data/com.termux/files/usr/bin/bash

set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$DIR/.pids"

stop_process() {
    local name="$1"
    local pidfile="$PID_DIR/$name.pid"

    if [ ! -f "$pidfile" ]; then
        echo "$name: not running"
        return
    fi

    local pid
    pid="$(cat "$pidfile")"

    if kill -0 "$pid" 2>/dev/null; then
        echo "Stopping $name (PID $pid)..."

        kill "$pid" 2>/dev/null

        for _ in {1..10}; do
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
            sleep 1
        done

        if kill -0 "$pid" 2>/dev/null; then
            echo "$name did not stop gracefully. Force stopping..."
            kill -9 "$pid" 2>/dev/null
        fi

        echo "$name stopped."
    else
        echo "$name: stale PID removed."
    fi

    rm -f "$pidfile"
}

echo "========================================"
echo "        STOPPING PHONE TO CCTV"
echo "========================================"

stop_process "viewer"
stop_process "bridge"
stop_process "mediamtx"

if command -v termux-wake-unlock >/dev/null 2>&1; then
    termux-wake-unlock
fi

echo
echo "All services stopped."