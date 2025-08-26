#!/bin/bash

#==============================================================================#
#                                🚇 Simple Tunnel 🚇                              #
#         Automatically creates a reverse SSH tunnel with password             #
#==============================================================================#

REMOTE_HOST="89.168.49.205"
REMOTE_USER="root"
SSH_PORT="22"
LOCAL_PORT="22"
MIN_PORT="10000"
MAX_PORT="65535"

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'
C_CYAN='\033[0;36m'
C_WHITE='\033[1;37m'

EMOJI_TUNNEL="🚇"
EMOJI_GEAR="⚙️"
EMOJI_LINK="🔗"
EMOJI_SUCCESS="✅"
EMOJI_ERROR="❌"
EMOJI_STOP="🛑"

generate_random_port() {
    echo $(( RANDOM % (MAX_PORT - MIN_PORT + 1) + MIN_PORT ))
}

install_sshpass() {
    if ! command -v sshpass &> /dev/null; then
        echo -e "${EMOJI_GEAR} Installing sshpass..."
        apt update >/dev/null 2>&1 && apt install -y sshpass >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${EMOJI_SUCCESS} sshpass installed!"
        else
            echo -e "${EMOJI_ERROR} Failed to install sshpass."
            exit 1
        fi
    fi
}

# --- Start Tunnel ---
install_sshpass

echo -e "Enter password for ${REMOTE_USER}@${REMOTE_HOST}:"
read -s VPS_PASSWORD
echo

REMOTE_PORT=$(generate_random_port)
echo -e "${EMOJI_TUNNEL} Creating tunnel from local ${LOCAL_PORT} → remote ${REMOTE_HOST}:${REMOTE_PORT}"

nohup sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no \
    -o ExitOnForwardFailure=yes \
    -N -R ${REMOTE_PORT}:localhost:${LOCAL_PORT} \
    ${REMOTE_USER}@${REMOTE_HOST} -p ${SSH_PORT} &> /tmp/tunnel_${REMOTE_PORT}.log &

PID=$!
sleep 2

if ps -p $PID > /dev/null; then
    echo -e "${EMOJI_SUCCESS} Tunnel established!"
    echo -e "  PID: $PID"
    echo -e "  Remote URL: ${REMOTE_HOST}:${REMOTE_PORT}"
    echo -e "  Log: /tmp/tunnel_${REMOTE_PORT}.log"
else
    echo -e "${EMOJI_ERROR} Tunnel failed to start."
    echo -e "Check log: /tmp/tunnel_${REMOTE_PORT}.log"
fi
