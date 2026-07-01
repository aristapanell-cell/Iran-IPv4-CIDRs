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
echo -e "${BLUE}ARISTA SCANNER${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}GitHub:${NC} ${BLUE}https://github.com/aristapanell-cell/AristaScanner${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${CYAN}Date:${NC} $(date '+%Y-%m-%d %H:%M:%S') ${GOLD}═══${NC}"
echo -e "${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${CYAN}System:${NC} $(uname -o 2>/dev/null || echo "Linux") ${GOLD}═══${NC}"
echo ""

# Options Menu
echo -e "${WHITE}OPTIONS${NC}"
echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
echo -e "  ${GREEN}▸ 1${NC}) ${WHITE}IPv4 SCAN${NC}  ${CYAN}•${NC} Find best IPv4 addresses"
echo -e "  ${GREEN}▸ 2${NC}) ${WHITE}IPv6 SCAN${NC}  ${CYAN}•${NC} Find best IPv6 addresses"
echo -e "  ${RED}▸ 0${NC}) ${WHITE}EXIT${NC}       ${CYAN}•${NC} Close scanner"
echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"

echo -en "\n${WHITE}┌─[${GREEN}SELECT${WHITE}]${NC} "
read -r user_input

if [ "$user_input" -eq 1 ]; then
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${CYAN}Scanning IPv4 addresses...${NC} ${GOLD}═══${NC}"
    
    # دریافت لیست آیپی‌ها
    temp_file=$(mktemp)
    echo "1" | bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/install.sh) 2>/dev/null | grep -oP '(\d{1,3}\.){3}\d{1,3}:\d+' > "$temp_file"
    
    clear
    
    if [ ! -s "$temp_file" ]; then
        echo -e "\n${GOLD}═══${NC} ${WHITE}[${RED}!${WHITE}]${NC} ${RED}No IPv4 addresses found!${NC} ${GOLD}═══${NC}"
    else
        echo -e "\n${WHITE}TOP 20 IPv4 ADDRESSES${NC}"
        echo -e "${BLUE}────────────────────────────────────────${NC}"
        
        count=0
        while IFS= read -r ip_port; do
            count=$((count+1))
            if [ $count -gt 20 ]; then
                break
            fi
            
            ip=$(echo "$ip_port" | cut -d: -f1)
            
            # پینگ با timeout کمتر
            latency=$(ping -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | head -1 | sed 's/.*time=//' | cut -d' ' -f1)
            
            if [ -z "$latency" ]; then
                latency="N/A"
                status="${RED}DOWN${NC}"
            elif [ "$(echo "$latency < 100" | bc 2>/dev/null)" = "1" ]; then
                status="${GREEN}FAST${NC}"
            elif [ "$(echo "$latency < 200" | bc 2>/dev/null)" = "1" ]; then
                status="${YELLOW}GOOD${NC}"
            else
                status="${RED}SLOW${NC}"
            fi
            
            # نمایش با echo ساده به جای printf
            echo -e "  $count.  $ip_port  ${CYAN}$latency${NC}  $status"
            
        done < "$temp_file"
        
        echo -e "${BLUE}────────────────────────────────────────${NC}"
        echo -e "${WHITE}Total: $count IP addresses found${NC}"
    fi
    
    rm -f "$temp_file"
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${CYAN}i${WHITE}]${NC} ${WHITE}Press Enter to continue...${NC} ${GOLD}═══${NC}"
    read
    exec "$0"
    
elif [ "$user_input" -eq 2 ]; then
    echo -e "\n${GOLD}═══${NC} ${WHITE}[${GREEN}+${WHITE}]${NC} ${CYAN}Scanning IPv6 addresses...${NC} ${GOLD}═══${NC}"
    
    # دریافت لیست آیپی‌ها
    temp_file=$(mktemp)
    echo "2" | bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/install.sh) 2>/dev/null | grep -oP '(\[?[a-fA-F\d:]+\]?\:\d+)' > "$temp_file"
    
    clear
    
    if [ ! -s "$temp_file" ]; then
        echo -e "\n${GOLD}═══${NC} ${WHITE}[${RED}!${WHITE}]${NC} ${RED}No IPv6 addresses found!${NC} ${GOLD}═══${NC}"
    else
        echo -e "\n${WHITE}TOP 20 IPv6 ADDRESSES${NC}"
        echo -e "${BLUE}─────────────────────────────────────────────────────${NC}"
        
        count=0
        while IFS= read -r ip_port; do
            count=$((count+1))
            if [ $count -gt 20 ]; then
                break
            fi
            
            ip=$(echo "$ip_port" | cut -d'[' -f2 | cut -d']' -f1)
            if [ -z "$ip" ]; then
                ip=$(echo "$ip_port" | cut -d: -f1)
            fi
            
            # پینگ با timeout کمتر
            latency=$(ping6 -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | head -1 | sed 's/.*time=//' | cut -d' ' -f1)
            
            if [ -z "$latency" ]; then
                latency="N/A"
                status="${RED}DOWN${NC}"
            elif [ "$(echo "$latency < 100" | bc 2>/dev/null)" = "1" ]; then
                status="${GREEN}FAST${NC}"
            elif [ "$(echo "$latency < 200" | bc 2>/dev/null)" = "1" ]; then
                status="${YELLOW}GOOD${NC}"
            else
                status="${RED}SLOW${NC}"
            fi
            
            # نمایش با echo ساده
            echo -e "  $count.  $ip_port  ${CYAN}$latency${NC}  $status"
            
        done < "$temp_file"
        
        echo -e "${BLUE}─────────────────────────────────────────────────────${NC}"
        echo -e "${WHITE}Total: $count IP addresses found${NC}"
    fi
    
    rm -f "$temp_file"
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
