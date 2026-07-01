#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${CYAN}*****************************************${NC}"
    echo -e "${CYAN}*${NC} ${RED}A${GREEN}R${YELLOW}I${PURPLE}S${CYAN}T${GREEN}A${NC} ${RED}S${GREEN}C${YELLOW}A${PURPLE}N${CYAN}N${GREEN}E${RED}R${NC}          ${CYAN}"
    echo -e "${CYAN}*${NC} ${RED}G${GREEN}I${YELLOW}T${PURPLE}H${CYAN}U${GREEN}B${NC} : ${PURPLE}https://github.com/aristapanell-cell/AristaScanner${NC} ${CYAN}"
    echo -e "${CYAN}*****************************************${NC}"
    echo -e "${CYAN}* ${GREEN}Date:${NC} $(date '+%Y-%m-%d %H:%M:%S') ${CYAN}*${NC}"
    echo ""
}

measure_latency() {
    local ip_port=$1
    local ip=$(echo $ip_port | cut -d: -f1)
    local latency=$(ping -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | awk -F'time=' '{ print $2 }' | cut -d' ' -f1)
    if [ -z "$latency" ]; then
        latency="N/A"
    fi
    printf "| %-21s | %-10s |\n" "$ip_port" "$latency"
}

display_table() {
    printf "+-----------------------+------------+\n"
    printf "| IP:Port               | Latency(ms) |\n"
    printf "+-----------------------+------------+\n"
    echo "$1" | head -n 10 | while read -r ip_port; do measure_latency "$ip_port"; done
    printf "+-----------------------+------------+\n"
}

scan_ipv4() {
    echo -e "${CYAN}Fetching IPv4 addresses...${NC}"
    ip_list=$(echo "1" | bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/install.sh) 2>/dev/null | grep -oP '(\d{1,3}\.){3}\d{1,3}:\d+')
    
    if [ -z "$ip_list" ]; then
        echo -e "${RED}No IPs found!${NC}"
        return
    fi
    
    clear
    echo -e "${GREEN}Top 10 IPv4 addresses with their latencies:${NC}"
    display_table "$ip_list"
}

scan_ipv6() {
    echo -e "${CYAN}Fetching IPv6 addresses...${NC}"
    ip_list=$(echo "2" | bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/install.sh) 2>/dev/null | grep -oP '(\[?[a-fA-F\d:]+\]?\:\d+)')
    
    if [ -z "$ip_list" ]; then
        echo -e "${RED}No IPv6 addresses found!${NC}"
        return
    fi
    
    clear
    echo -e "${GREEN}Top 10 IPv6 addresses with their latencies:${NC}"
    printf "+---------------------------------------------+------------+\n"
    printf "| IP:Port                                     | Latency(ms) |\n"
    printf "+---------------------------------------------+------------+\n"
    echo "$ip_list" | head -n 10 | while read -r ip_port; do
        ip=$(echo $ip_port | cut -d'[' -f2 | cut -d']' -f1)
        latency=$(ping6 -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | awk -F'time=' '{ print $2 }' | cut -d' ' -f1)
        if [ -z "$latency" ]; then
            latency="N/A"
        fi
        printf "| %-45s | %-10s |\n" "$ip_port" "$latency"
    done
    printf "+---------------------------------------------+------------+\n"
}

while true; do
    show_header
    echo -e "${CYAN}+----+---------------------------------------------+${NC}"
    echo -e "${GREEN}| No | Option                                      |${NC}"
    echo -e "${CYAN}+----+---------------------------------------------+${NC}"
    printf "${CYAN}| ${YELLOW}%-2s ${CYAN}| ${YELLOW}%-43s ${CYAN}|\n" "1" "IPv4 scan"
    printf "${CYAN}| ${YELLOW}%-2s ${CYAN}| ${YELLOW}%-43s ${CYAN}|\n" "2" "IPv6 scan"
    printf "${CYAN}| ${YELLOW}%-2s ${CYAN}| ${YELLOW}%-43s ${CYAN}|\n" "0" "Exit"
    echo -e "${CYAN}+----+---------------------------------------------+${NC}"
    echo -en "${GREEN}Enter your choice: ${NC}"
    read -r user_input

    case $user_input in
        1) scan_ipv4 ;;
        2) scan_ipv6 ;;
        0) 
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}Invalid input. Please enter 1, 2, or 0${NC}"
            sleep 1
            ;;
    esac
done
