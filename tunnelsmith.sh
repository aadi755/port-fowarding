#!/bin/bash
# 🚇 Tunnelsmith - password based version
# by aadi755

CONFIG_FILE="$HOME/.tunnelsmith.conf"

# Ensure sshpass exists
if ! command -v sshpass &>/dev/null; then
    echo "📦 Installing sshpass..."
    apt-get update -y && apt-get install -y sshpass
fi

function setup() {
    echo "🔑 Setup Tunnelsmith (password based)"
    read -p "Enter SSH Host: " HOST
    read -p "Enter SSH Port (default 22): " PORT
    read -p "Enter SSH Username: " USER
    read -s -p "Enter SSH Password: " PASS
    echo ""

    cat > "$CONFIG_FILE" <<EOF
HOST=$HOST
PORT=${PORT:-22}
USER=$USER
PASS=$PASS
EOF

    echo "✅ Config saved at $CONFIG_FILE"
}

function make() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Config not found. Run: $0 setup"
        exit 1
    fi

    source "$CONFIG_FILE"
    LOCAL_PORT=$1

    if [ -z "$LOCAL_PORT" ]; then
        echo "Usage: $0 make <local_port>"
        exit 1
    fi

    echo "⚙️  Creating tunnel on port $LOCAL_PORT..."
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -N -L $LOCAL_PORT:localhost:$LOCAL_PORT $USER@$HOST -p $PORT &
    echo "✅ Tunnel started (PID $!)"
}

function list() {
    ps aux | grep "[s]shpass -p" || echo "❌ No tunnels running"
}

function kill_tunnel() {
    PID=$1
    if [ -z "$PID" ]; then
        echo "Usage: $0 kill <pid>"
        exit 1
    fi
    kill -9 $PID && echo "🛑 Tunnel $PID killed"
}

function killall() {
    pkill -f "sshpass -p" && echo "🛑 All tunnels killed"
}

case "$1" in
    setup) setup ;;
    make) make $2 ;;
    list) list ;;
    kill) kill_tunnel $2 ;;
    killall) killall ;;
    *) echo "Usage: $0 {setup|make|list|kill|killall}" ;;
esac
