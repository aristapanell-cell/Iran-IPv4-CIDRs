#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗"
    echo -e "║                                                          ║"
    echo -e "║   █████╗ ██████╗ ██╗███████╗████████╗ █████╗             ║"
    echo -e "║  ██╔══██╗██╔══██╗██║██╔════╝╚══██╔══╝██╔══██╗            ║"
    echo -e "║  ███████║██████╔╝██║███████╗   ██║   ███████║            ║"
    echo -e "║  ██╔══██║██╔══██╗██║╚════██║   ██║   ██╔══██║            ║"
    echo -e "║  ██║  ██║██║  ██║██║███████║   ██║   ██║  ██║            ║"
    echo -e "║  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝            ║"
    echo -e "║                                                          ║"
    echo -e "║           Arista Scanner - IP Scanner                   ║"
    echo -e "╚══════════════════════════════════════════════════════════╝${NC}"
}

get_ips() {
    local count=$1
    local ips=""
    
    ips=$(curl -sL --max-time 5 https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/install.sh 2>/dev/null | bash 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -$count | sort -u)
    
    if [ -z "$ips" ]; then
        ips=$(curl -sL --max-time 5 https://raw.githubusercontent.com/v2rayA/v2rayA/main/ip.txt 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -$count | sort -u)
    fi
    
    if [ -z "$ips" ]; then
        ips=$(curl -sL --max-time 5 https://raw.githubusercontent.com/alanhg/CloudflareSpeedTest/master/ip.txt 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -$count | sort -u)
    fi
    
    if [ -z "$ips" ]; then
        ips=$(curl -sL --max-time 5 https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -$count | sort -u)
    fi
    
    if [ -z "$ips" ]; then
        ips="104.16.0.1
104.16.0.2
104.16.0.3
104.16.0.4
104.16.0.5
104.16.0.6
104.16.0.7
104.16.0.8
104.16.0.9
104.16.0.10"
    fi
    
    echo "$ips" | head -$count
}

measure_latency() {
    local ip=$1
    local latency=$(ping -c 1 -W 2 $ip 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1)
    if [ -n "$latency" ]; then
        echo "$ip|$latency"
    fi
}

scan() {
    local count=$1
    show_header
    
    echo -e "\n${BLUE}[*]${NC} Fetching ${count} IPs..."
    ips=$(get_ips $count)
    
    if [ -z "$ips" ]; then
        echo -e "${RED}No IPs found!${NC}"
        echo -e "\n${DIM}Press Enter to continue...${NC}"
        read
        return
    fi
    
    local total=$(echo "$ips" | wc -l)
    echo -e "${BLUE}[*]${NC} Testing ${total} IPs...\n"
    
    results=""
    local i=0
    for ip in $ips; do
        i=$((i+1))
        printf "\r${BLUE}[$i/$total]${NC} Testing: $ip     "
        result=$(measure_latency $ip)
        if [ -n "$result" ]; then
            results="$results\n$result"
        fi
    done
    
    echo -e "\n\n${CYAN}═══════════════════════════════════════════════"
    echo -e "Results"
    echo -e "═══════════════════════════════════════════════${NC}"
    
    if [ -n "$results" ]; then
        echo -e "\n${BOLD}${GREEN}══════════ TOP 10 IPS ══════════${NC}\n"
        echo -e "${CYAN}  IP Address                Latency${NC}"
        echo -e "${DIM}  -----------------------  ----------${NC}"
        
        local idx=0
        echo -e "$results" | sort -t'|' -k2 -n | head -10 | while IFS='|' read -r ip latency; do
            idx=$((idx+1))
            if (( $(echo "$latency < 50" | bc -l 2>/dev/null) )); then
                color=$GREEN
            elif (( $(echo "$latency < 100" | bc -l 2>/dev/null) )); then
                color=$YELLOW
            else
                color=$RED
            fi
            printf "  ${color}%02d. %-22s  %6.1fms${NC}\n" "$idx" "$ip" "$latency"
        done
        echo -e "\n${GREEN}✓ Copy the IPs above${NC}"
    else
        echo -e "\n${YELLOW}⚠ No responsive IPs found.${NC}"
    fi
    
    echo -e "\n${DIM}Press Enter to continue...${NC}"
    read
}

while true; do
    show_header
    echo -e "\n${GREEN}1.${NC} Fast Scan ${DIM}(50 IPs)${NC}"
    echo -e "${GREEN}2.${NC} Normal Scan ${DIM}(100 IPs)${NC}"
    echo -e "${GREEN}3.${NC} Deep Scan ${DIM}(200 IPs)${NC}"
    echo -e "${GREEN}4.${NC} Custom Count"
    echo -e "\n${RED}0.${NC} Exit"
    echo -en "\n${BLUE}Enter your choice: ${NC}"
    read choice
    
    case $choice in
        0) 
            echo -e "\n${GREEN}Goodbye!${NC}"
            exit 0 
            ;;
        1) scan 50 ;;
        2) scan 100 ;;
        3) scan 200 ;;
        4) 
            echo -en "${BLUE}Enter number of IPs: ${NC}"
            read count
            if [[ $count =~ ^[0-9]+$ ]] && [ $count -gt 0 ]; then
                scan $count
            else
                echo -e "${RED}Invalid number!${NC}"
                sleep 1
            fi
            ;;
        *) 
            echo -e "${RED}Invalid choice!${NC}"
            sleep 1 
            ;;
    esac
done
