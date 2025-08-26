#!/bin/bash

#==============================================================================#
#                                                                              #
#                                 🚇 Port  ADVIK  🚇                            #
#           A cool and friendly script for creating reverse SSH tunnels.       #
#                                                                              #
#==============================================================================#

# --- Configuration ---
CONFIG_FILE="$HOME/.tunnelsmith.conf"

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    REMOTE_HOST="89.168.49.205"
    REMOTE_USER="tunnel"
    SSH_PORT="22"
    MIN_PORT="10000"
    MAX_PORT="65535"
fi

# --- Colors and Emojis ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'
C_CYAN='\033[0;36m'
C_WHITE='\033[1;37m'

EMOJI_TUNNEL="🚇"
EMOJI_SPARKLE="✨"
EMOJI_GEAR="⚙️"
EMOJI_LINK="🔗"
EMOJI_SUCCESS="✅"
EMOJI_ERROR="❌"
EMOJI_STOP="🛑"
EMOJI_LIST="📋"
EMOJI_WAVE="👋"
EMOJI_KEY="🔑"
EMOJI_CONFIG="📝"
EMOJI_INSTALL="📦"
EMOJI_LOCK="🔒"

# --- Helper Functions ---
usage() {
    echo -e "${C_WHITE}${EMOJI_TUNNEL} Tunnelsmith - a friendly tunnel manager${C_RESET}"
    echo -e "---------------------------------------------------------------"
    echo -e "${C_YELLOW}Usage:${C_RESET} ${C_CYAN}$0 ${C_PURPLE}<command> [options]${C_RESET}\n"
    echo -e "${C_PURPLE}Commands:${C_RESET}"
    echo -e "  ${C_CYAN}make <local_port>${C_RESET}    ${EMOJI_GEAR} Create a new tunnel from a local port"
    echo -e "  ${C_CYAN}list${C_RESET}                 ${EMOJI_LIST} List all active tunnels"
    echo -e "  ${C_CYAN}kill <pid>${C_RESET}           ${EMOJI_STOP} Stop a specific tunnel by PID"
    echo -e "  ${C_CYAN}killall${C_RESET}              ${EMOJI_STOP} Stop all active tunnels"
    echo -e "  ${C_CYAN}config${C_RESET}               ${EMOJI_CONFIG} Show current configuration"
    echo -e "  ${C_CYAN}setup${C_RESET}                ${EMOJI_KEY} Setup SSH authentication"
    echo -e "  ${C_CYAN}help${C_RESET}                 ${EMOJI_WAVE} Show this help message"
    echo -e "---------------------------------------------------------------"
}

generate_random_port() {
    echo $(( RANDOM % (MAX_PORT - MIN_PORT + 1) + MIN_PORT ))
}

check_ssh_key() {
    if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
        echo -e "${EMOJI_KEY} ${C_YELLOW}No SSH key found. Generating one now...${C_RESET}"
        ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N "" -q
        echo -e "${EMOJI_SUCCESS} ${C_GREEN}SSH key generated!${C_RESET}"
    fi
}

install_sshpass() {
    if ! command -v sshpass &> /dev/null; then
        echo -e "${EMOJI_INSTALL} ${C_YELLOW}Installing sshpass...${C_RESET}"
        apt update > /dev/null 2>&1 && apt install -y sshpass > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${EMOJI_SUCCESS} ${C_GREEN}sshpass installed!${C_RESET}"
        else
            echo -e "${EMOJI_ERROR} ${C_RED}Failed to install sshpass.${C_RESET}"
            return 1
        fi
    fi
    return 0
}

secure_password_input() {
    echo -e "${EMOJI_LOCK} ${C_YELLOW}Enter VPS password for ${REMOTE_USER}@${REMOTE_HOST}:${C_RESET} "
    read -s -r VPS_PASSWORD
    echo
}

setup_ssh() {
    check_ssh_key
    secure_password_input
    install_sshpass

    if command -v sshpass &> /dev/null; then
        echo -e "${EMOJI_KEY} ${C_YELLOW}Copying SSH key to ${REMOTE_USER}@${REMOTE_HOST}...${C_RESET}"
        SSH_COPY_OUTPUT=$(sshpass -p "$VPS_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no -p $SSH_PORT ${REMOTE_USER}@${REMOTE_HOST} 2>&1)
        if [ $? -eq 0 ]; then
            echo -e "${EMOJI_SUCCESS} ${C_GREEN}SSH key copied successfully!${C_RESET}"
            echo -e "You can now create tunnels without entering a password."
            unset VPS_PASSWORD
        else
            echo -e "${EMOJI_ERROR} ${C_RED}Failed to copy SSH key:${C_RESET}"
            echo "$SSH_COPY_OUTPUT"
            echo -e "\n${C_YELLOW}Manual setup may be required.${C_RESET}"
            manual_ssh_setup
        fi
    else
        echo -e "${EMOJI_ERROR} ${C_RED}sshpass not available. Manual setup required.${C_RESET}"
        manual_ssh_setup
    fi
    unset VPS_PASSWORD
}

manual_ssh_setup() {
    echo -e "${EMOJI_KEY} ${C_YELLOW}Manual SSH setup required:${C_RESET}"
    echo -e "Public key: ${C_CYAN}$(cat ~/.ssh/id_rsa.pub)${C_RESET}"
    echo -e "Please run on your VPS:"
    echo -e "${C_WHITE}mkdir -p ~/.ssh && echo '$(cat ~/.ssh/id_rsa.pub)' >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys${C_RESET}"
    echo -e "\nOr manually copy the key using:"
    echo -e "${C_WHITE}ssh-copy-id -p ${SSH_PORT} ${REMOTE_USER}@${REMOTE_HOST}${C_RESET}"
}

show_config() {
    echo -e "${EMOJI_CONFIG} ${C_BLUE}Tunnelsmith Configuration:${C_RESET}"
    echo -e "  ${C_WHITE}Remote Host:${C_RESET} ${C_CYAN}${REMOTE_HOST}${C_RESET}"
    echo -e "  ${C_WHITE}Remote User:${C_RESET} ${C_CYAN}${REMOTE_USER}${C_RESET}"
    echo -e "  ${C_WHITE}SSH Port:${C_RESET} ${C_CYAN}${SSH_PORT}${C_RESET}"
    echo -e "  ${C_WHITE}Port Range:${C_RESET} ${C_CYAN}${MIN_PORT}-${MAX_PORT}${C_RESET}"
    echo -e "  ${C_WHITE}Config File:${C_RESET} ${C_CYAN}${CONFIG_FILE}${C_RESET}"
    echo -e "  ${C_WHITE}SSH Key Setup:${C_RESET} ${C_GREEN}$(if [ -f ~/.ssh/id_rsa.pub ]; then echo "Ready"; else echo "Not configured"; fi)${C_RESET}"
    echo ""
}

check_ssh_connection() {
    ssh -o BatchMode=yes -o ConnectTimeout=5 -p $SSH_PORT ${REMOTE_USER}@${REMOTE_HOST} "echo -n" 2>/dev/null
    return $?
}

# --- Main Logic ---
if [ -z "$1" ]; then
    usage
    exit 1
fi

case "$1" in
    setup)
        setup_ssh
        ;;

    make|list|kill|killall|config|help)
        # For all other commands, check SSH first
        if ! check_ssh_connection; then
            echo -e "${EMOJI_ERROR} ${C_RED}SSH key authentication not setup.${C_RESET}"
            echo -e "Run ${C_CYAN}tunnelsmith setup${C_RESET} to configure passwordless access."
            exit 1
        fi
        ;;
esac

# --- Process commands ---
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

        nohup ssh -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 \
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
        ;;

    list)
        echo -e "\n${EMOJI_LIST} ${C_BLUE}Active tunnels to ${C_WHITE}${REMOTE_HOST}${C_RESET}..."
        PIDS=$(pgrep -af "ssh.*-R.*${REMOTE_HOST}")
        if [ -n "$PIDS" ]; then
            echo -e "------------------------------------------------------------------"
            echo -e "${C_WHITE}PID\t\tREMOTE PORT\tLOCAL PORT${C_RESET}"
            echo -e "------------------------------------------------------------------"
            echo "$PIDS" | while read line; do
                pid=$(echo "$line" | awk '{print $1}')
                remote_p=$(echo "$line" | grep -oP '\-R\s+\K[0-9]+(?=:localhost:)')
                local_p=$(echo "$line" | grep -oP ':localhost:\K[0-9]+')
                echo -e "${C_YELLOW}${pid}${C_RESET}\t\t${C_CYAN}${remote_p}${C_RESET}\t\t${C_PURPLE}${local_p}${C_RESET}"
            done
            echo -e "------------------------------------------------------------------\n"
        else
            echo -e "${EMOJI_SPARKLE} ${C_GREEN}No active tunnels found.${C_RESET}\n"
        fi
        ;;

    kill)
        PID_TO_KILL=$2
        if [[ -z "$PID_TO_KILL" || ! "$PID_TO_KILL" =~ ^[0-9]+$ ]]; then
            echo -e "\n${EMOJI_ERROR} ${C_RED}Error: Valid PID required.${C_RESET}"
            echo -e "Find PIDs with: ${C_CYAN}$0 list${C_RESET}\n"
            exit 1
        fi
        if ps -p $PID_TO_KILL > /dev/null; then
            kill $PID_TO_KILL
            echo -e "\n${EMOJI_STOP} ${C_GREEN}Terminated tunnel PID: ${C_YELLOW}${PID_TO_KILL}${C_RESET}\n"
        else
            echo -e "\n${EMOJI_ERROR} ${C_RED}No process with PID: ${C_YELLOW}${PID_TO_KILL}${C_RESET}\n"
        fi
        ;;

    killall)
        echo -e "\n${EMOJI_STOP} ${C_BLUE}Terminating all tunnels to ${C_WHITE}${REMOTE_HOST}${C_RESET}..."
        PIDS_TO_KILL=$(pgrep -f "ssh.*-R.*${REMOTE_HOST}")
        if [ -n "$PIDS_TO_KILL" ]; then
            echo -e "${C_YELLOW}Terminating processes:${C_RESET}"
            pgrep -af "ssh.*-R.*${REMOTE_HOST}"
            kill $PIDS_TO_KILL
            echo -e "\n${EMOJI_SUCCESS} ${C_GREEN}All tunnels terminated.${C_RESET}\n"
        else
            echo -e "${EMOJI_SPARKLE} ${C_GREEN}No active tunnels to kill.${C_RESET}\n"
        fi
        ;;

    config)
        show_config
        ;;

    help)
        usage
        ;;

    *)
        echo -e "\n${EMOJI_ERROR} ${C_RED}Unknown command: ${C_YELLOW}$1${C_RESET}"
        usage
        exit 1
        ;;
esac
