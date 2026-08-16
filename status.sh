#!/data/data/com.termux/files/usr/bin/bash

set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$DIR/.pids"

get_cmdline() {
    local pid="$1"

    if [ -r "/proc/$pid/cmdline" ]; then
        tr '\0' ' ' < "/proc/$pid/cmdline"
    fi
}

is_process_owner() {
    local pid="$1"
    local expected="$2"

    [[ "$pid" =~ ^[0-9]+$ ]] || return 1

    kill -0 "$pid" 2>/dev/null || return 1

    local cmdline
    cmdline="$(get_cmdline "$pid")"

    [[ "$cmdline" == *"$expected"* ]]
}

check_process() {
    local name="$1"
    local expected="$2"

    local pidfile="$PID_DIR/$name.pid"
    local pgidfile="$PID_DIR/$name.pgid"

    if [ ! -f "$pidfile" ]; then
        printf "%-12s %s\n" "$name:" "STOPPED"
        return
    fi

    local pid
    pid="$(cat "$pidfile" 2>/dev/null || true)"

    if is_process_owner "$pid" "$expected"; then
        local pgid="unknown"

        if [ -f "$pgidfile" ]; then
            pgid="$(cat "$pgidfile" 2>/dev/null || echo "unknown")"
        fi

        printf "%-12s %s (PID %s, PGID %s)\n" \
            "$name:" \
            "RUNNING" \
            "$pid" \
            "$pgid"
    else
        printf "%-12s %s (stale/invalid PID %s)\n" \
            "$name:" \
            "STOPPED" \
            "$pid"
    fi
}

echo "========================================"
echo "         PHONE TO CCTV STATUS"
echo "========================================"

check_process "mediamtx" "mediamtx"
check_process "bridge" "bridge.sh"
check_process "viewer" "node server.js"

echo
echo "Processes:"
ps -ef | grep -E '[m]ediamtx|[f]fmpeg|[n]ode server.js|[b]ridge.sh' || true

echo
echo "Logs:"
echo "  MediaMTX: $DIR/logs/mediamtx.log"
echo "  Bridge:   $DIR/logs/bridge.log"
echo "  Viewer:   $DIR/logs/viewer.log"
