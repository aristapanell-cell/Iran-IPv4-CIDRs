#!/bin/bash

clear

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GOLD='\033[1;33m'
NC='\033[0m'

# Header
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}                                                                            ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}              ${WHITE}▸${NC} ${BLUE}ARISTA SCANNER${NC} ${WHITE}◂${NC}       ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}                                                                            ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}         ${WHITE}GitHub:${NC} ${BLUE}https://github.com/aristapanell-cell/AristaScanner${NC}         ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}                                                                            ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${CYAN}Date:${NC} $(date '+%Y-%m-%d %H:%M:%S') ${GOLD}═══${NC}"
echo -e "${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${CYAN}System:${NC} $(uname -o 2>/dev/null || echo "Linux") ${GOLD}═══${NC}"
echo ""

# Options Menu
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│${NC}  ${WHITE}▸ OPTIONS${NC}                                           ${BLUE}│${NC}"
echo -e "${BLUE}├────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BLUE}│${NC}  ${GREEN}▸ 1${NC}) ${WHITE}IPv4 SCAN${NC}  ${CYAN}•${NC} Find best IPv4 addresses          ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  ${GREEN}▸ 2${NC}) ${WHITE}IPv6 SCAN${NC}  ${CYAN}•${NC} Find best IPv6 addresses          ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  ${RED}▸ 0${NC}) ${WHITE}EXIT${NC}       ${CYAN}•${NC} Close scanner                     ${BLUE}│${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"

echo -en "\n${WHITE}┌─[${GREEN}SELECT${WHITE}]${NC} "
read -r user_input

if [ "$user_input" -eq 1 ]; then
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${CYAN}Scanning IPv4 addresses...${NC} ${GOLD}═══${NC}"
    ip_list=$(echo "1" | bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/install.sh) 2>/dev/null | grep -oP '(\d{1,3}\.){3}\d{1,3}:\d+')
    clear
    if [ -z "$ip_list" ]; then
        echo -e "\n${GOLD}═══${NC} ${WHITE}[${RED}!${WHITE}]${NC} ${RED}No IPv4 addresses found!${NC} ${GOLD}═══${NC}"
    else
        echo -e "\n${BLUE}┌──────────────────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│${NC}  ${GREEN}●${NC} ${WHITE}TOP 20 IPv4 ADDRESSES (IP:PORT)${NC}                                        ${BLUE}│${NC}"
        echo -e "${BLUE}├──────────────────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│${NC}  ${CYAN}#${NC}  ${CYAN}IP:PORT${NC}                                   ${CYAN}LATENCY${NC}    ${CYAN}STATUS${NC}                     ${BLUE}│${NC}"
        echo -e "${BLUE}├──────────────────────────────────────────────────────────────────────────────────────┤${NC}"
        idx=0
        echo "$ip_list" | head -n 20 | while read -r ip_port; do
            idx=$((idx+1))
            ip=$(echo "$ip_port" | cut -d: -f1)
            port=$(echo "$ip_port" | cut -d: -f2)
            latency=$(ping -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | awk -F'time=' '{ print $2 }' | cut -d' ' -f1)
            if [ -z "$latency" ]; then
                latency="N/A"
                status="${RED}DOWN${NC}"
            elif [ "$latency" -lt 100 ] 2>/dev/null; then
                status="${GREEN}FAST${NC}"
            elif [ "$latency" -lt 200 ] 2>/dev/null; then
                status="${YELLOW}GOOD${NC}"
            else
                status="${RED}SLOW${NC}"
            fi
            printf "${BLUE}│${NC}  ${WHITE}%02d${NC}  %-37s  ${CYAN}%-6s${NC}  %-6s  ${BLUE}│${NC}\n" "$idx" "$ip_port" "$latency" "$status"
        done
        echo -e "${BLUE}└──────────────────────────────────────────────────────────────────────────────────────┘${NC}"

        echo -e "\n${BLUE}┌──────────────────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│${NC}  ${GREEN}●${NC} ${WHITE}TOP 20 IPv4 ADDRESSES (IP ONLY)${NC}                                     ${BLUE}│${NC}"
        echo -e "${BLUE}├──────────────────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│${NC}  ${CYAN}#${NC}  ${CYAN}IP ADDRESS${NC}                              ${CYAN}LATENCY${NC}    ${CYAN}STATUS${NC}                     ${BLUE}│${NC}"
        echo -e "${BLUE}├──────────────────────────────────────────────────────────────────────────────────────┤${NC}"
        idx=0
        echo "$ip_list" | head -n 20 | while read -r ip_port; do
            idx=$((idx+1))
            ip=$(echo "$ip_port" | cut -d: -f1)
            latency=$(ping -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | awk -F'time=' '{ print $2 }' | cut -d' ' -f1)
            if [ -z "$latency" ]; then
                latency="N/A"
                status="${RED}DOWN${NC}"
            elif [ "$latency" -lt 100 ] 2>/dev/null; then
                status="${GREEN}FAST${NC}"
            elif [ "$latency" -lt 200 ] 2>/dev/null; then
                status="${YELLOW}GOOD${NC}"
            else
                status="${RED}SLOW${NC}"
            fi
            printf "${BLUE}│${NC}  ${WHITE}%02d${NC}  %-29s  ${CYAN}%-6s${NC}  %-6s  ${BLUE}│${NC}\n" "$idx" "$ip" "$latency" "$status"
        done
        echo -e "${BLUE}└──────────────────────────────────────────────────────────────────────────────────────┘${NC}"
    fi
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${CYAN}i${WHITE}]${NC} ${WHITE}Press Enter to continue...${NC} ${GOLD}═══${NC}"
    read
    exec "$0"
elif [ "$user_input" -eq 2 ]; then
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${CYAN}Scanning IPv6 addresses...${NC} ${GOLD}═══${NC}"
    ip_list=$(echo "2" | bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/install.sh) 2>/dev/null | grep -oP '(\[?[a-fA-F\d:]+\]?\:\d+)')
    clear
    if [ -z "$ip_list" ]; then
        echo -e "\n${GOLD}═══${NC} ${WHITE}[${RED}!${WHITE}]${NC} ${RED}No IPv6 addresses found!${NC} ${GOLD}═══${NC}"
    else
        echo -e "\n${BLUE}┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│${NC}  ${GREEN}●${NC} ${WHITE}TOP 20 IPv6 ADDRESSES (IP:PORT)${NC}                                                       ${BLUE}│${NC}"
        echo -e "${BLUE}├────────────────────────────────────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│${NC}  ${CYAN}#${NC}  ${CYAN}IP:PORT${NC}                                                            ${CYAN}LATENCY${NC}    ${CYAN}STATUS${NC}       ${BLUE}│${NC}"
        echo -e "${BLUE}├────────────────────────────────────────────────────────────────────────────────────────────────────────┤${NC}"
        idx=0
        echo "$ip_list" | head -n 20 | while read -r ip_port; do
            idx=$((idx+1))
            ip=$(echo "$ip_port" | cut -d'[' -f2 | cut -d']' -f1)
            if [ -z "$ip" ]; then
                ip=$(echo "$ip_port" | cut -d: -f1)
            fi
            latency=$(ping6 -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | awk -F'time=' '{ print $2 }' | cut -d' ' -f1)
            if [ -z "$latency" ]; then
                latency="N/A"
                status="${RED}DOWN${NC}"
            elif [ "$latency" -lt 100 ] 2>/dev/null; then
                status="${GREEN}FAST${NC}"
            elif [ "$latency" -lt 200 ] 2>/dev/null; then
                status="${YELLOW}GOOD${NC}"
            else
                status="${RED}SLOW${NC}"
            fi
            printf "${BLUE}│${NC}  ${WHITE}%02d${NC}  %-59s  ${CYAN}%-6s${NC}  %-6s  ${BLUE}│${NC}\n" "$idx" "$ip_port" "$latency" "$status"
        done
        echo -e "${BLUE}└────────────────────────────────────────────────────────────────────────────────────────────────────────┘${NC}"

        echo -e "\n${BLUE}┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│${NC}  ${GREEN}●${NC} ${WHITE}TOP 20 IPv6 ADDRESSES (IP ONLY)${NC}                                                    ${BLUE}│${NC}"
        echo -e "${BLUE}├────────────────────────────────────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│${NC}  ${CYAN}#${NC}  ${CYAN}IP ADDRESS${NC}                                                       ${CYAN}LATENCY${NC}    ${CYAN}STATUS${NC}       ${BLUE}│${NC}"
        echo -e "${BLUE}├────────────────────────────────────────────────────────────────────────────────────────────────────────┤${NC}"
        idx=0
        echo "$ip_list" | head -n 20 | while read -r ip_port; do
            idx=$((idx+1))
            ip=$(echo "$ip_port" | cut -d'[' -f2 | cut -d']' -f1)
            if [ -z "$ip" ]; then
                ip=$(echo "$ip_port" | cut -d: -f1)
            fi
            latency=$(ping6 -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | awk -F'time=' '{ print $2 }' | cut -d' ' -f1)
            if [ -z "$latency" ]; then
                latency="N/A"
                status="${RED}DOWN${NC}"
            elif [ "$latency" -lt 100 ] 2>/dev/null; then
                status="${GREEN}FAST${NC}"
            elif [ "$latency" -lt 200 ] 2>/dev/null; then
                status="${YELLOW}GOOD${NC}"
            else
                status="${RED}SLOW${NC}"
            fi
            printf "${BLUE}│${NC}  ${WHITE}%02d${NC}  %-51s  ${CYAN}%-6s${NC}  %-6s  ${BLUE}│${NC}\n" "$idx" "$ip" "$latency" "$status"
        done
        echo -e "${BLUE}└────────────────────────────────────────────────────────────────────────────────────────────────────────┘${NC}"
    fi
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${CYAN}i${WHITE}]${NC} ${WHITE}Press Enter to continue...${NC} ${GOLD}═══${NC}"
    read
    exec "$0"
elif [ "$user_input" -eq 0 ]; then
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${GREEN}Goodbye!${NC} ${GOLD}═══${NC}"
    exit 0
else
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${RED}!${WHITE}]${NC} ${RED}Invalid input. Please enter 1, 2, or 0${NC} ${GOLD}═══${NC}"
    sleep 2
    exec "$0"
fi
