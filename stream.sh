#!/bin/bash
# Chai & Code — YouTube Live Stream
# DJ engine + branded video loop → RTMP (1080p)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load .env if present
if [ -f "${SCRIPT_DIR}/.env" ]; then
    set -a
    source "${SCRIPT_DIR}/.env"
    set +a
fi

RTMP_URL="${RTMP_URL:?Set RTMP_URL in .env or environment (e.g. rtmp://a.rtmp.youtube.com/live2/YOUR_STREAM_KEY)}"
VIDEO_LOOP="${SCRIPT_DIR}/video/branded_loop.mp4"
LOG="${SCRIPT_DIR}/logs/stream.log"
DJ_LOG="${SCRIPT_DIR}/logs/dj_engine.log"

mkdir -p "${SCRIPT_DIR}/logs"
echo "[$(date)] Starting Chai & Code stream (1080p)" | tee -a "$LOG"

python3 "${SCRIPT_DIR}/dj_engine.py" 2>>"$DJ_LOG" | \
ffmpeg \
  -stream_loop -1 -re -i "$VIDEO_LOOP" \
  -f s16le -ar 44100 -ac 2 -thread_queue_size 512 -i pipe:0 \
  -c:v libx264 -preset ultrafast \
  -b:v 4500k -maxrate 5000k -bufsize 10000k \
  -pix_fmt yuv420p -g 48 -r 24 \
  -c:a aac -b:a 192k -ar 44100 \
  -f flv \
  -loglevel warning \
  "$RTMP_URL" 2>&1 | tee -a "$LOG"
