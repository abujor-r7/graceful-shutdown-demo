#!/bin/bash
mkdir -p /opt/fake-app/bin

cat <<'EOF' > /opt/fake-app/bin/runner.sh
#!/usr/bin/env bash

LOG_FILE="/tmp/sigterm.log"

# ShutdownTimeRequired, default is 120 sec
[ -z "$1" ] && DELAY=120 || DELAY=$1

handle_sigterm() {
  trap '' SIGTERM
  echo "$(date '+%Y-%m-%d %H:%M:%S') - SIGTERM received, shutting down..." >> "$LOG_FILE"
  sleep $DELAY
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Exit after graceful shutdown" >> "$LOG_FILE"
  exit 0
}

trap handle_sigterm SIGTERM

echo "$(date '+%Y-%m-%d %H:%M:%S') - Script started (PID $$)" >> "$LOG_FILE"

while true; do
  sleep 1
done
EOF

chmod +x /opt/fake-app/bin/runner.sh


cat <<EOF > /etc/systemd/system/fake-app.service
[Unit]
Description=Fake App
After=network.target

[Service]
Type=simple
ExecStart=/opt/fake-app/bin/runner.sh 240
KillSignal=SIGTERM
TimeoutStopSec=20
Restart=no

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now fake-app.service
