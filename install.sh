#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                                                          ║"
echo "║   █████╗ ██████╗ ██╗███████╗████████╗ █████╗             ║"
echo "║  ██╔══██╗██╔══██╗██║██╔════╝╚══██╔══╝██╔══██╗            ║"
echo "║  ███████║██████╔╝██║███████╗   ██║   ███████║            ║"
echo "║  ██╔══██║██╔══██╗██║╚════██║   ██║   ██╔══██║            ║"
echo "║  ██║  ██║██║  ██║██║███████║   ██║   ██║  ██║            ║"
echo "║  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝            ║"
echo "║                                                          ║"
echo "║           Arista Scanner - Termux Installer              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [ -d "/data/data/com.termux" ]; then
    echo -e "${GREEN}✓ Termux detected${NC}"
else
    echo -e "${YELLOW}⚠ Not running in Termux${NC}"
fi

echo -e "\n${BLUE}[*] Installing dependencies...${NC}"
pkg install -y python python-pip

echo -e "\n${BLUE}[*] Installing Python packages...${NC}"
pip install aiohttp 2>/dev/null || echo "aiohttp already installed"

echo -e "\n${BLUE}[*] Downloading project...${NC}"
cd ~
rm -rf arista-scanner
git clone https://github.com/aristapanell-cell/AristaScanner.git arista-scanner

cd ~/arista-scanner
chmod +x arista

ln -sf ~/arista-scanner/arista ~/../usr/bin/arista 2>/dev/null || echo "Symlink not created"

echo -e "\n${GREEN}✅ Installation Complete!${NC}"
echo -e "\n${CYAN}📦 Arista Scanner installed in: ~/arista-scanner${NC}"
echo -e "\n${YELLOW}Quick Start:${NC}"
echo -e "  ${WHITE}arista${NC}        ${BLUE}# Run scanner with menu${NC}"
echo -e "  ${WHITE}arista --count 100${NC}    ${BLUE}# Scan 100 IPs${NC}"
echo -e "  ${WHITE}arista --help${NC}        ${BLUE}# Show all options${NC}"
