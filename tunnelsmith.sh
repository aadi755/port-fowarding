#!/bin/bash
# ==========================================================
# TunnelSmith (Password Version) - Secure SSH Tunnel Manager
# ==========================================================

# Colors
C_RESET="\033[0m"
C_RED="\033[31m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_BLUE="\033[34m"
C_PURPLE="\033[35m"
C_CYAN="\033[36m"
C_WHITE="\033[37m"

# Emojis
EMOJI_TUNNEL="🌐"
EMOJI_SUCCESS="✅"
EMOJI_ERROR="❌"
EMOJI_INFO="ℹ️"
EMOJI_STOP="🛑"
EMOJI_LINK="🔗"
EMOJI_LOCK="🔒"
EMOJI_GEAR="⚙️"

# Config
REMOTE_HOST="89.168.49.205"   # 🔹 Your VPS IP
SSH_PORT="22"                 # 🔹 VPS SSH Port
REMOTE_USER="root"            # 🔹 Always root

# Function to generate random port
generate_random_port() {
    echo $((RANDOM % (65535 - 20000 + 1) + 20000))
}

# ==========================================================
# Main Commands
# ==========================================================
case "$1" in
    make)
        LOCAL_PORT=$2
        if [[ -z "$LOCAL_PORT" || ! "$LOCAL_PORT" =~ ^[0-9]+$ ]]; then
            echo -e "\n${EMOJI_ERROR} ${C_RED}Error: Valid local port required.${C_RESET}"
            echo -e "Example: ${C_CYAN}$0 make 80${C_RESET}\n"
            exit 1
        fi

        REMOTE_PORT=$(generate_random_port)
        echo -e "\n${EMOJI_TUNNEL} ${C_BLUE}Creating tunnel...${C_RESET}"
        echo -e "${EMOJI_GEAR} ${C_YELLOW}Connecting to ${C_WHITE}${REMOTE_USER}@${REMOTE_HOST}${C_RESET}"
        echo -e "${EMOJI_LINK} ${C_CYAN}Forwarding:${C_RESET} Local ${C_WHITE}${LOCAL_PORT}${C_RESET} → Remote ${C_WHITE}${REMOTE_PORT}${C_RESET}\n"

        # Ask for password
        echo -ne "${EMOJI_LOCK} ${C_YELLOW}Enter password for ${REMOTE_USER}@${REMOTE_HOST}:${C_RESET} "
        read -s VPS_PASSWORD
        echo

        # Use sshpass for password-based tunnel
        nohup sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 \
            -N -R ${REMOTE_PORT}:localhost:${LOCAL_PORT} \
            ${REMOTE_USER}@${REMOTE_HOST} -p ${SSH_PORT} &> /tmp/tunnel_${REMOTE_PORT}.log &

        PID=$!
        sleep 2

        if ps -p $PID > /dev/null; then
            echo -e "${EMOJI_SUCCESS} ${C_GREEN}Tunnel established!${C_RESET}"
            echo -e "  ${C_WHITE}PID:${C_RESET} ${C_YELLOW}${PID}${C_RESET}"
            echo -e "  ${C_WHITE}Remote URL:${C_RESET} ${C_CYAN}http://${REMOTE_HOST}:${REMOTE_PORT}${C_RESET}"
            echo -e "  ${C_WHITE}Log:${C_RESET} /tmp/tunnel_${REMOTE_PORT}.log"
            echo -e "\n${EMOJI_STOP} To stop: ${C_PURPLE}tunnelsmith kill ${PID}${C_RESET}\n"
        else
            echo -e "${EMOJI_ERROR} ${C_RED}Tunnel failed to start.${C_RESET}"
            echo -e "Check log: ${C_YELLOW}cat /tmp/tunnel_${REMOTE_PORT}.log${C_RESET}\n"
            [ ! -s "/tmp/tunnel_${REMOTE_PORT}.log" ] && rm "/tmp/tunnel_${REMOTE_PORT}.log"
        fi

        unset VPS_PASSWORD
        ;;

    kill)
        if [[ -z "$2" ]]; then
            echo -e "\n${EMOJI_ERROR} ${C_RED}Error: PID required.${C_RESET}"
            echo -e "Example: ${C_CYAN}$0 kill 12345${C_RESET}\n"
            exit 1
        fi

        if kill "$2" >/dev/null 2>&1; then
            echo -e "\n${EMOJI_STOP} ${C_GREEN}Tunnel stopped (PID: $2)${C_RESET}\n"
        else
            echo -e "\n${EMOJI_ERROR} ${C_RED}No such process: $2${C_RESET}\n"
        fi
        ;;

    list)
        echo -e "\n${EMOJI_INFO} ${C_BLUE}Active tunnels:${C_RESET}\n"
        ps -ef | grep "ssh.*${REMOTE_HOST}" | grep -v grep || \
            echo -e "${C_YELLOW}No active tunnels${C_RESET}\n"
        ;;

    logs)
        if [[ -z "$2" ]]; then
            echo -e "\n${EMOJI_ERROR} ${C_RED}Error: Remote port required.${C_RESET}"
            echo -e "Example: ${C_CYAN}$0 logs 23456${C_RESET}\n"
            exit 1
        fi
        echo -e "\n${EMOJI_INFO} ${C_BLUE}Logs for tunnel (Remote port: $2)${C_RESET}\n"
        tail -f "/tmp/tunnel_$2.log"
        ;;

    help|--help|-h|"")
        echo -e "\n${EMOJI_INFO} ${C_BLUE}TunnelSmith (Password Mode) - Commands:${C_RESET}\n"
        echo -e "  ${C_WHITE}make <port>${C_RESET}   → Create tunnel (asks for password)"
        echo -e "  ${C_WHITE}kill <PID>${C_RESET}    → Stop tunnel by PID"
        echo -e "  ${C_WHITE}list${C_RESET}          → List active tunnels"
        echo -e "  ${C_WHITE}logs <rport>${C_RESET}  → Show tunnel logs"
        echo -e "  ${C_WHITE}help${C_RESET}          → Show this help menu\n"
        ;;

    *)
        echo -e "\n${EMOJI_ERROR} ${C_RED}Invalid command.${C_RESET}"
        echo -e "Run ${C_CYAN}$0 help${C_RESET} for usage.\n"
        ;;
esac
