#!/data/data/com.termux/files/usr/bin/bash

set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$DIR/.pids"
LOG_DIR="$DIR/logs"

mkdir -p "$PID_DIR" "$LOG_DIR"

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

get_pgid() {
    local pid="$1"
    ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' '
}

is_service_running() {
    local name="$1"
    local expected="$2"
    local pidfile="$PID_DIR/$name.pid"

    [ -f "$pidfile" ] || return 1

    local pid
    pid="$(cat "$pidfile" 2>/dev/null || true)"

    is_process_owner "$pid" "$expected"
}

start_process() {
    local name="$1"
    local command="$2"
    local expected="$3"

    local pidfile="$PID_DIR/$name.pid"
    local pgidfile="$PID_DIR/$name.pgid"
    local logfile="$LOG_DIR/$name.log"

    if [ -f "$pidfile" ]; then
        local old_pid
        old_pid="$(cat "$pidfile" 2>/dev/null || true)"

        if is_process_owner "$old_pid" "$expected"; then
            echo "$name is already running (PID $old_pid)"
            return
        fi

        echo "$name: removing stale PID files."
        rm -f "$pidfile" "$pgidfile"
    fi

    echo "Starting $name..."

    : > "$logfile"

    setsid bash -c "exec $command" >> "$logfile" 2>&1 &
    local pid=$!

    echo "$pid" > "$pidfile"

    sleep 1

    if is_process_owner "$pid" "$expected"; then
        local pgid
        pgid="$(get_pgid "$pid")"

        if [ -n "$pgid" ]; then
            echo "$pgid" > "$pgidfile"
        fi

        echo "$name started successfully (PID $pid)"
    else
        echo "ERROR: $name failed to start. Check:"
        echo "  $logfile"

        rm -f "$pidfile" "$pgidfile"
    fi
}

if ! command -v setsid >/dev/null 2>&1; then
    echo "ERROR: setsid is required but was not found."
    echo "Install it with:"
    echo "  pkg install util-linux"
    exit 1
fi

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
    "cd \"$DIR/mediamtx\" && ./mediamtx mediamtx.yml" \
    "mediamtx"

sleep 2

start_process \
    "bridge" \
    "\"$DIR/bridge.sh\"" \
    "bridge.sh"

start_process \
    "viewer" \
    "cd \"$DIR/viewer\" && node server.js" \
    "node server.js"

echo
echo "========================================"
echo "      PHONE TO CCTV IS RUNNING"
echo "========================================"
echo
echo "Run ./status.sh to check services."
echo "Run ./stop.sh to stop everything."
echo

"$DIR/status.sh"
