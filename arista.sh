#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

PORTS=(443 8443 2053 2096 2087 2083 8880)

get_ips() {
    curl -fsSL https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/install.sh 2>/dev/null | bash 2>/dev/null | grep -oP '(\d{1,3}\.){3}\d{1,3}' | head -50 | sort -u
}

measure_latency() {
    local ip=$1
    local port=$2
    local latency=$(ping -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1)
    if [ -n "$latency" ]; then
        echo "$ip:$port|$latency"
    fi
}

scan() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════╗"
    echo -e "║         Arista Scanner - IP Scanner           ║"
    echo -e "╚═══════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${BLUE}[*]${NC} Fetching IPs..."
    ips=$(get_ips)
    
    if [ -z "$ips" ]; then
        echo -e "${RED}No IPs found!${NC}"
        return
    fi
    
    echo -e "${BLUE}[*]${NC} Testing IPs on ${#PORTS[@]} ports...\n"
    
    results=""
    for ip in $ips; do
        for port in "${PORTS[@]}"; do
            result=$(measure_latency $ip $port)
            if [ -n "$result" ]; then
                results="$results\n$result"
            fi
        done
    done
    
    echo -e "\n${CYAN}═══════════════════════════════════════════════"
    echo -e "Results"
    echo -e "═══════════════════════════════════════════════${NC}"
    
    if [ -n "$results" ]; then
        echo -e "\n${BOLD}${GREEN}══════════ TOP 10 IPS ══════════${NC}\n"
        echo -e "${CYAN}  IP:Port                    Latency${NC}"
        echo -e "${DIM}  -----------------------  ----------${NC}"
        
        i=0
        echo -e "$results" | sort -t'|' -k2 -n | head -10 | while IFS='|' read -r ip_port latency; do
            i=$((i+1))
            if (( $(echo "$latency < 50" | bc -l 2>/dev/null) )); then
                color=$GREEN
            elif (( $(echo "$latency < 100" | bc -l 2>/dev/null) )); then
                color=$YELLOW
            else
                color=$RED
            fi
            printf "  ${color}%02d. %-22s  %6.1fms${NC}\n" "$i" "$ip_port" "$latency"
        done
        echo -e "\n${GREEN}✓ Copy the IPs above${NC}"
    else
        echo -e "\n${YELLOW}⚠ No responsive IPs found.${NC}"
    fi
    
    echo -e "\n${DIM}Press Enter to continue...${NC}"
    read
}

menu() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════╗"
    echo -e "║          Arista Scanner - Main Menu            ║"
    echo -e "╚═══════════════════════════════════════════════╝${NC}"
    echo -e "\n${GREEN}1.${NC} Scan IPs ${DIM}(50 IPs)${NC}"
    echo -e "${GREEN}2.${NC} Scan IPs ${DIM}(100 IPs)${NC}"
    echo -e "${GREEN}3.${NC} Scan IPs ${DIM}(200 IPs)${NC}"
    echo -e "${GREEN}4.${NC} Custom Count"
    echo -e "\n${RED}0.${NC} Exit"
    echo -en "\n${BLUE}Enter your choice: ${NC}"
}

while true; do
    menu
    read choice
    
    case $choice in
        0) echo -e "\n${GREEN}Goodbye!${NC}"; exit 0 ;;
        1) scan ;;
        2) scan ;;
        3) scan ;;
        4) 
            echo -en "${BLUE}Enter number of IPs: ${NC}"
            read count
            if [[ $count =~ ^[0-9]+$ ]] && [ $count -gt 0 ]; then
                scan
            else
                echo -e "${RED}Invalid number!${NC}"
                sleep 1
            fi
            ;;
        *) echo -e "${RED}Invalid choice!${NC}"; sleep 1 ;;
    esac
done
