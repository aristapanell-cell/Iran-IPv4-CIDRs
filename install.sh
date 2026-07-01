#!/bin/bash

echo -e "\033[0;36m"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   █████╗ ██████╗ ██╗███████╗████████╗ █████╗             ║"
echo "║  ██╔══██╗██╔══██╗██║██╔════╝╚══██╔══╝██╔══██╗            ║"
echo "║  ███████║██████╔╝██║███████╗   ██║   ███████║            ║"
echo "║  ██╔══██║██╔══██╗██║╚════██║   ██║   ██╔══██║            ║"
echo "║  ██║  ██║██║  ██║██║███████║   ██║   ██║  ██║            ║"
echo "║  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝            ║"
echo "║           Arista Scanner - Termux Installer              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

echo -e "\n\033[0;34m[*]\033[0m Installing Arista Scanner..."

curl -sL https://raw.githubusercontent.com/aristapanell-cell/AristaScanner/main/arista.sh -o ~/arista
chmod +x ~/arista
ln -sf ~/arista ~/../usr/bin/arista 2>/dev/null

echo -e "\n\033[0;32m✅ Installation Complete!\033[0m"
echo -e "\n\033[0;36m📦 Arista Scanner installed\033[0m"
echo -e "\n\033[1;33mQuick Start:\033[0m"
echo -e "  \033[1;37marista\033[0m        \033[0;34m# Run scanner\033[0m"
