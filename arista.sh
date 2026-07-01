#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GOLD='\033[1;33m'
NC='\033[0m'

main_menu() {
    clear
    echo -e "${BLUE}ARISTA SCANNER${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}ARISTA MATRIX PIPELINE${NC} : ${GREEN}https://github.com/aristapanell-cell/ARISTA-MATRIX-PIPELINE${NC}"
    echo -e "${RED}AristaPanel${NC} : ${GREEN}https://github.com/aristapanell-cell/AriataPanel${NC}"
    echo -e "${RED}Telegram Channel${NC} : ${GREEN}@aristapanel${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${CYAN}Date:${NC} $(date '+%Y-%m-%d %H:%M:%S') ${GOLD}═══${NC}"
    echo -e "${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${CYAN}System:${NC} $(uname -o 2>/dev/null || echo "Linux") ${GOLD}═══${NC}"
    echo ""
    echo -e "${WHITE}OPTIONS${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}▸ 1${NC}) ${WHITE}IPv4 SCAN${NC}  ${CYAN}•${NC} Find best IPv4 addresses"
    echo -e "  ${GREEN}▸ 2${NC}) ${WHITE}IPv6 SCAN${NC}  ${CYAN}•${NC} Find best IPv6 addresses"
    echo -e "  ${RED}▸ 0${NC}) ${WHITE}EXIT${NC}       ${CYAN}•${NC} Close scanner"
    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
    echo -en "\n${WHITE}┌─[${GREEN}SELECT${WHITE}]${NC} "
    read -r user_input
    case $user_input in
        1) ipv4_scan ;;
        2) ipv6_scan ;;
        0) echo -e "\n${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${GREEN}Goodbye!${NC} ${GOLD}═══${NC}"; exit 0 ;;
        *) echo -e "\n${RED}Invalid input!${NC}"; sleep 1; main_menu ;;
    esac
}

ipv4_scan() {
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${CYAN}Scanning IPv4 addresses...${NC} ${GOLD}═══${NC}"
    temp_file=$(mktemp)
    echo "1" | bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/install.sh) 2>/dev/null | grep -oP '(\d{1,3}\.){3}\d{1,3}:\d+' > "$temp_file"
    clear
    if [ ! -s "$temp_file" ]; then
        echo -e "\n${RED}No IPv4 addresses found!${NC}"
    else
        echo -e "\n${RED}╔════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}     ${WHITE}🔥 TOP 10 IPv4 ADDRESSES (IP:PORT)${NC}                          ${RED}║${NC}"
        echo -e "${RED}╠════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${RED}║${NC}  ${CYAN}#${NC}  ${CYAN}IP:PORT${NC}                                   ${CYAN}LATENCY${NC}    ${CYAN}STATUS${NC}       ${RED}║${NC}"
        echo -e "${RED}╠════════════════════════════════════════════════════════════════════╣${NC}"
        colors=("${GREEN}" "${CYAN}" "${YELLOW}" "${PURPLE}" "${BLUE}" "${GOLD}" "${WHITE}" "${GREEN}" "${CYAN}" "${YELLOW}")
        count=0
        while IFS= read -r ip_port; do
            count=$((count+1)); [ $count -gt 10 ] && break
            ip=$(echo "$ip_port" | cut -d: -f1)
            latency=$(ping -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | head -1 | sed 's/.*time=//' | cut -d' ' -f1)
            [ -z "$latency" ] && latency="N/A" && status="${RED}DOWN${NC}" || {
                [ "$(echo "$latency < 100" | bc 2>/dev/null)" = "1" ] && status="${GREEN}FAST${NC}" || {
                    [ "$(echo "$latency < 200" | bc 2>/dev/null)" = "1" ] && status="${YELLOW}GOOD${NC}" || status="${RED}SLOW${NC}"
                }
            }
            color="${colors[$((count-1))]}"
            printf "${RED}║${NC}  ${color}%02d${NC}  %-37s  ${CYAN}%-6s${NC}  %-6s  ${RED}║${NC}\n" "$count" "$ip_port" "$latency" "$status"
        done < "$temp_file"
        echo -e "${RED}╚════════════════════════════════════════════════════════════════════╝${NC}"
        echo -e "\n${RED}╔════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}     ${WHITE}🔥 TOP 10 IPv4 ADDRESSES (IP ONLY)${NC}                           ${RED}║${NC}"
        echo -e "${RED}╠════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${RED}║${NC}  ${CYAN}#${NC}  ${CYAN}IP ADDRESS${NC}                              ${CYAN}LATENCY${NC}    ${CYAN}STATUS${NC}       ${RED}║${NC}"
        echo -e "${RED}╠════════════════════════════════════════════════════════════════════╣${NC}"
        count=0
        while IFS= read -r ip_port; do
            count=$((count+1)); [ $count -gt 10 ] && break
            ip=$(echo "$ip_port" | cut -d: -f1)
            latency=$(ping -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | head -1 | sed 's/.*time=//' | cut -d' ' -f1)
            [ -z "$latency" ] && latency="N/A" && status="${RED}DOWN${NC}" || {
                [ "$(echo "$latency < 100" | bc 2>/dev/null)" = "1" ] && status="${GREEN}FAST${NC}" || {
                    [ "$(echo "$latency < 200" | bc 2>/dev/null)" = "1" ] && status="${YELLOW}GOOD${NC}" || status="${RED}SLOW${NC}"
                }
            }
            color="${colors[$((count-1))]}"
            printf "${RED}║${NC}  ${color}%02d${NC}  %-29s  ${CYAN}%-6s${NC}  %-6s  ${RED}║${NC}\n" "$count" "$ip" "$latency" "$status"
        done < "$temp_file"
        echo -e "${RED}╚════════════════════════════════════════════════════════════════════╝${NC}"
    fi
    rm -f "$temp_file"
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${CYAN}i${WHITE}]${NC} ${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}[1]${NC}  ${WHITE}Back to Main Menu${NC}"
    echo -e "  ${RED}[0]${NC}  ${WHITE}Exit${NC}"
    echo -en "${GOLD}═══${NC} ${WHITE}┌─[${GREEN}SELECT${WHITE}]${NC} "
    read -r choice
    [ "$choice" -eq 0 ] && { echo -e "\n${GREEN}Goodbye!${NC}"; exit 0; } || main_menu
}

ipv6_scan() {
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${CYAN}Scanning IPv6 addresses...${NC} ${GOLD}═══${NC}"
    temp_file=$(mktemp)
    echo "2" | bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/install.sh) 2>/dev/null | grep -oP '(\[?[a-fA-F\d:]+\]?\:\d+)' > "$temp_file"
    clear
    if [ ! -s "$temp_file" ]; then
        echo -e "\n${RED}No IPv6 addresses found!${NC}"
    else
        echo -e "\n${RED}╔════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}     ${WHITE}🔥 TOP 10 IPv6 ADDRESSES (IP:PORT)${NC}                                          ${RED}║${NC}"
        echo -e "${RED}╠════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${RED}║${NC}  ${CYAN}#${NC}  ${CYAN}IP:PORT${NC}                                                            ${CYAN}LATENCY${NC}    ${CYAN}STATUS${NC}  ${RED}║${NC}"
        echo -e "${RED}╠════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        colors=("${GREEN}" "${CYAN}" "${YELLOW}" "${PURPLE}" "${BLUE}" "${GOLD}" "${WHITE}" "${GREEN}" "${CYAN}" "${YELLOW}")
        count=0
        while IFS= read -r ip_port; do
            count=$((count+1)); [ $count -gt 10 ] && break
            ip=$(echo "$ip_port" | cut -d'[' -f2 | cut -d']' -f1); [ -z "$ip" ] && ip=$(echo "$ip_port" | cut -d: -f1)
            latency=$(ping6 -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | head -1 | sed 's/.*time=//' | cut -d' ' -f1)
            [ -z "$latency" ] && latency="N/A" && status="${RED}DOWN${NC}" || {
                [ "$(echo "$latency < 100" | bc 2>/dev/null)" = "1" ] && status="${GREEN}FAST${NC}" || {
                    [ "$(echo "$latency < 200" | bc 2>/dev/null)" = "1" ] && status="${YELLOW}GOOD${NC}" || status="${RED}SLOW${NC}"
                }
            }
            color="${colors[$((count-1))]}"
            printf "${RED}║${NC}  ${color}%02d${NC}  %-59s  ${CYAN}%-6s${NC}  %-6s  ${RED}║${NC}\n" "$count" "$ip_port" "$latency" "$status"
        done < "$temp_file"
        echo -e "${RED}╚════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo -e "\n${RED}╔════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}     ${WHITE}🔥 TOP 10 IPv6 ADDRESSES (IP ONLY)${NC}                                           ${RED}║${NC}"
        echo -e "${RED}╠════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${RED}║${NC}  ${CYAN}#${NC}  ${CYAN}IP ADDRESS${NC}                                                       ${CYAN}LATENCY${NC}    ${CYAN}STATUS${NC}  ${RED}║${NC}"
        echo -e "${RED}╠════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        count=0
        while IFS= read -r ip_port; do
            count=$((count+1)); [ $count -gt 10 ] && break
            ip=$(echo "$ip_port" | cut -d'[' -f2 | cut -d']' -f1); [ -z "$ip" ] && ip=$(echo "$ip_port" | cut -d: -f1)
            latency=$(ping6 -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | head -1 | sed 's/.*time=//' | cut -d' ' -f1)
            [ -z "$latency" ] && latency="N/A" && status="${RED}DOWN${NC}" || {
                [ "$(echo "$latency < 100" | bc 2>/dev/null)" = "1" ] && status="${GREEN}FAST${NC}" || {
                    [ "$(echo "$latency < 200" | bc 2>/dev/null)" = "1" ] && status="${YELLOW}GOOD${NC}" || status="${RED}SLOW${NC}"
                }
            }
            color="${colors[$((count-1))]}"
            printf "${RED}║${NC}  ${color}%02d${NC}  %-51s  ${CYAN}%-6s${NC}  %-6s  ${RED}║${NC}\n" "$count" "$ip" "$latency" "$status"
        done < "$temp_file"
        echo -e "${RED}╚════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    fi
    rm -f "$temp_file"
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${CYAN}i${WHITE}]${NC} ${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}[1]${NC}  ${WHITE}Back to Main Menu${NC}"
    echo -e "  ${RED}[0]${NC}  ${WHITE}Exit${NC}"
    echo -en "${GOLD}═══${NC} ${WHITE}┌─[${GREEN}SELECT${WHITE}]${NC} "
    read -r choice
    [ "$choice" -eq 0 ] && { echo -e "\n${GREEN}Goodbye!${NC}"; exit 0; } || main_menu
}

main_menu
