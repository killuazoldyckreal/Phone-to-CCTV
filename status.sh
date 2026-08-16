#!/data/data/com.termux/files/usr/bin/bash

set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$DIR/.pids"

check_process() {
    local name="$1"
    local pidfile="$PID_DIR/$name.pid"

    if [ ! -f "$pidfile" ]; then
        printf "%-12s %s\n" "$name:" "STOPPED"
        return
    fi

    local pid
    pid="$(cat "$pidfile")"

    if kill -0 "$pid" 2>/dev/null; then
        printf "%-12s %s (PID %s)\n" "$name:" "RUNNING" "$pid"
    else
        printf "%-12s %s (stale PID %s)\n" "$name:" "STOPPED" "$pid"
    fi
}

echo "========================================"
echo "         PHONE TO CCTV STATUS"
echo "========================================"

check_process "mediamtx"
check_process "bridge"
check_process "viewer"

echo
echo "Processes:"
ps -ef | grep -E '[m]ediamtx|[f]fmpeg|[n]ode server.js' || true

echo
echo "Logs:"
echo "  MediaMTX: $DIR/logs/mediamtx.log"
echo "  Bridge:   $DIR/logs/bridge.log"
echo "  Viewer:   $DIR/logs/viewer.log"