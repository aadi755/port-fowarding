#!/bin/bash
#==============================================================================#
#                                🚇 Simple Tunnel 🚇                            #
#        Creates a reverse SSH tunnel to 89.168.49.205, port 22               #
#==============================================================================#

REMOTE_HOST="89.168.49.205"
REMOTE_USER="root"
REMOTE_PORT=22
LOCAL_PORT=22

# Ask for password
read -s -p "Enter password for $REMOTE_USER@$REMOTE_HOST: " VPS_PASSWORD
echo

# Check for sshpass
if ! command -v sshpass &>/dev/null; then
    echo "Installing sshpass..."
    apt update >/dev/null 2>&1
    apt install -y sshpass >/dev/null 2>&1
fi

# Start tunnel
nohup sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no \
    -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 \
    -N -R ${REMOTE_PORT}:localhost:${LOCAL_PORT} \
    ${REMOTE_USER}@${REMOTE_HOST} -p 22 &> /tmp/tunnel_22.log &

PID=$!
sleep 1

if ps -p $PID &>/dev/null; then
    echo "✅ Tunnel created!"
    echo "PID: $PID"
    echo "Remote: $REMOTE_HOST:$REMOTE_PORT → Local: $LOCAL_PORT"
    echo "Log file: /tmp/tunnel_22.log"
else
    echo "❌ Tunnel failed. Check log: /tmp/tunnel_22.log"
fi
