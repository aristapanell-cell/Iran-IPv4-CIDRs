#!/bin/bash
echo "Removing Arista Scanner..."
rm -rf ~/arista-scanner
rm -f ~/../usr/bin/arista 2>/dev/null
echo "Uninstalled successfully"
