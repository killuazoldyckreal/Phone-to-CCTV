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

process_group_exists() {
    local pgid="$1"

    [[ "$pgid" =~ ^[0-9]+$ ]] || return 1

    kill -0 "-$pgid" 2>/dev/null
}

stop_process() {
    local name="$1"
    local expected="$2"

    local pidfile="$PID_DIR/$name.pid"
    local pgidfile="$PID_DIR/$name.pgid"

    if [ ! -f "$pidfile" ]; then
        echo "$name: not running"
        return
    fi

    local pid
    pid="$(cat "$pidfile" 2>/dev/null || true)"

    if ! is_process_owner "$pid" "$expected"; then
        echo "$name: stale or invalid PID removed."
        rm -f "$pidfile" "$pgidfile"
        return
    fi

    local pgid="$pid"

    if [ -f "$pgidfile" ]; then
        local saved_pgid
        saved_pgid="$(cat "$pgidfile" 2>/dev/null || true)"

        if [[ "$saved_pgid" =~ ^[0-9]+$ ]]; then
            pgid="$saved_pgid"
        fi
    fi

    echo "Stopping $name (PID $pid, PGID $pgid)..."

    kill -TERM "-$pgid" 2>/dev/null || true

    for _ in {1..10}; do
        if ! process_group_exists "$pgid"; then
            break
        fi

        sleep 1
    done

    if process_group_exists "$pgid"; then
        echo "$name did not stop gracefully. Force stopping..."

        kill -KILL "-$pgid" 2>/dev/null || true

        sleep 1
    fi

    if process_group_exists "$pgid"; then
        echo "WARNING: $name process group may still be running."
    else
        echo "$name stopped."
    fi

    rm -f "$pidfile" "$pgidfile"
}

echo "========================================"
echo "        STOPPING PHONE TO CCTV"
echo "========================================"

stop_process "viewer" "node server.js"
stop_process "bridge" "bridge.sh"
stop_process "mediamtx" "mediamtx"

if command -v termux-wake-unlock >/dev/null 2>&1; then
    termux-wake-unlock
fi

echo
echo "All services stopped."
