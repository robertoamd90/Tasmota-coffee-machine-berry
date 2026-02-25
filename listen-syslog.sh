#!/bin/bash
# Listens for Tasmota syslog UDP packets and appends to a timestamped log file.
# No dependencies required (uses macOS built-in python3).
# Tasmota setup (run once from web console):
#   LogHost <your-mac-ip>
#   LogPort 64514
#   SysLog 4
#
# Usage:
#   ./listen-syslog.sh          # interactive (Ctrl+C to stop)
#   ./listen-syslog.sh -d       # detached background mode
#   ./listen-syslog.sh --stop   # stop any running listener

PORT=64514

kill_listeners() {
  local PIDS=$(lsof -ti UDP:$PORT 2>/dev/null)
  if [ -n "$PIDS" ]; then
    echo "[syslog] Stopping listener(s) on UDP $PORT (PID $PIDS)"
    kill $PIDS 2>/dev/null
    sleep 0.5
    return 0
  fi
  return 1
}

if [ "$1" = "--stop" ]; then
  kill_listeners || echo "[syslog] No listener running on UDP $PORT"
  exit 0
fi

DETACH=false
[ "$1" = "-d" ] && DETACH=true

mkdir -p log
kill_listeners

LOGFILE="log/tasmota-$(date +%Y%m%d_%H%M%S).log"

PYSCRIPT=$(cat <<'PYEOF'
import socket, re, sys

logfile = sys.argv[1]
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(('', int(sys.argv[2])))
sock.settimeout(1.0)

try:
    with open(logfile, 'a') as f:
        while True:
            try:
                data, _ = sock.recvfrom(65535)
            except socket.timeout:
                continue
            text = data.decode('utf-8', errors='replace')
            for msg in re.split(r'(?=<\d+>)', text):
                msg = msg.strip()
                if msg:
                    print(msg, flush=True)
                    f.write(msg + '\n')
                    f.flush()
except KeyboardInterrupt:
    pass
PYEOF
)

if [ "$DETACH" = true ]; then
  echo "$PYSCRIPT" | nohup python3 - "$LOGFILE" "$PORT" > /dev/null 2>&1 &
  disown $!
  echo "[syslog] Started in background (PID $!)"
  echo "[syslog] Log: $LOGFILE"
  echo "[syslog] Stop with: $0 --stop"
else
  echo "[syslog] Listening on UDP $PORT → $LOGFILE"
  echo "[syslog] Press Ctrl+C to stop"
  echo "$PYSCRIPT" | python3 - "$LOGFILE" "$PORT" &
  PYTHON_PID=$!
  trap "echo ''; echo '[syslog] Stopped.'; kill $PYTHON_PID 2>/dev/null; wait $PYTHON_PID 2>/dev/null" INT TERM EXIT
  wait $PYTHON_PID
fi
