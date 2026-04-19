#!/bin/bash
# Chai & Code Stream Watchdog
# Monitors the stream and auto-restarts if ffmpeg or dj_engine dies.
# Usage: nohup bash watchdog.sh > logs/watchdog.log 2>&1 &

STREAM_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_INTERVAL=30  # seconds between checks
RESTART_COOLDOWN=15  # seconds to wait before restarting (YouTube needs ~10s)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Watchdog started. Checking every ${CHECK_INTERVAL}s."

while true; do
    sleep "$CHECK_INTERVAL"

    ffmpeg_alive=$(pgrep -f "flv rtmp://.*youtube" | head -1)
    dj_alive=$(pgrep -f "dj_engine.py" | head -1)

    if [ -z "$ffmpeg_alive" ] || [ -z "$dj_alive" ]; then
        log "⚠️  Stream down! ffmpeg=${ffmpeg_alive:-DEAD} dj_engine=${dj_alive:-DEAD}"
        log "Killing remnants..."
        killall -9 ffmpeg python3 2>/dev/null
        sleep "$RESTART_COOLDOWN"
        log "Restarting stream..."
        cd "$STREAM_DIR" && nohup bash stream.sh > logs/stream_out.log 2>&1 &
        sleep 10

        # Verify restart
        if pgrep -f "flv rtmp://.*youtube" > /dev/null; then
            log "✅ Stream restarted successfully."
        else
            log "❌ Restart failed! Will retry next cycle."
        fi
    fi
done
