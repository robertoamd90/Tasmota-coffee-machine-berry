#!/bin/bash
# Listens for Tasmota syslog UDP packets (port 64514) and appends to a timestamped log file.
# No dependencies required (uses macOS built-in python3).
# Tasmota setup (run once from web console):
#   LogHost <your-mac-ip>
#   LogPort 64514
#   SysLog 4

mkdir -p log

# Kill any leftover listener on the port
EXISTING=$(lsof -ti UDP:64514 2>/dev/null)
if [ -n "$EXISTING" ]; then
  echo "[syslog] Killing existing listener(s) on UDP 64514: PID $EXISTING"
  kill -9 $EXISTING 2>/dev/null
  sleep 0.5
fi

LOGFILE="log/tasmota-$(date +%Y%m%d_%H%M%S).log"

echo "[syslog] Listening on UDP 64514 → $LOGFILE"
echo "[syslog] Press Ctrl+C to stop"

python3 - "$LOGFILE" <<'EOF'
import socket, re, sys

logfile = sys.argv[1]
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(('', 64514))

with open(logfile, 'a') as f:
    while True:
        data, _ = sock.recvfrom(65535)
        text = data.decode('utf-8', errors='replace')
        for msg in re.split(r'(?=<\d+>)', text):
            msg = msg.strip()
            if msg:
                print(msg, flush=True)
                f.write(msg + '\n')
                f.flush()
EOF
