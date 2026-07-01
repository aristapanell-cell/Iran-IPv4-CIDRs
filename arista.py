#!/usr/bin/env python3

import subprocess
import re
import sys
import time
import socket
from typing import List, Tuple, Optional

class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    MAGENTA = '\033[95m'
    WHITE = '\033[97m'
    RESET = '\033[0m'
    BOLD = '\033[1m'
    DIM = '\033[2m'

class AristaScanner:
    def __init__(self):
        self.ports = [443, 8443, 2053, 2096, 2087, 2083, 8880]

    def get_ips(self) -> List[str]:
        try:
            cmd = "bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/warp/main/endip/install.sh) 2>/dev/null"
            result = subprocess.run(['bash', '-c', cmd], capture_output=True, text=True, timeout=30)
            ips = re.findall(r'(\d{1,3}\.){3}\d{1,3}', result.stdout)
            return list(dict.fromkeys(ips))[:50]
        except:
            return self.fallback_ips()

    def fallback_ips(self) -> List[str]:
        ips = []
        ranges = ['104.16.0.0/12', '104.24.0.0/13', '141.101.0.0/16']
        import random, ipaddress
        for cidr in ranges:
            try:
                network = ipaddress.ip_network(cidr, strict=False)
                start = int(network.network_address)
                end = int(network.broadcast_address)
                for _ in range(10):
                    ip_int = random.randint(start + 1, end - 1)
                    ips.append(str(ipaddress.ip_address(ip_int)))
            except:
                pass
        return ips[:30]

    def ping_ip(self, ip: str, port: int) -> Tuple[str, Optional[float]]:
        try:
            start = time.time()
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1.0)
            result = sock.connect_ex((ip, port))
            sock.close()
            if result == 0:
                latency = (time.time() - start) * 1000
                return (f"{ip}:{port}", latency)
        except:
            pass
        return (f"{ip}:{port}", None)

    def scan(self, count: int = 50):
        print(f"\n{Colors.CYAN}╔═══════════════════════════════════════════════╗")
        print(f"║         Arista Scanner - IP Scanner           ║")
        print(f"╚═══════════════════════════════════════════════╝{Colors.RESET}")
        
        print(f"\n{Colors.BLUE}[*]{Colors.RESET} Fetching IPs...")
        ips = self.get_ips()[:count]
        if not ips:
            print(f"{Colors.RED}No IPs found!{Colors.RESET}")
            return
        
        total = len(ips) * len(self.ports)
        print(f"{Colors.BLUE}[*]{Colors.RESET} Testing {len(ips)} IPs on {len(self.ports)} ports...\n")
        
        results = []
        tested = 0
        
        for ip in ips:
            for port in self.ports:
                tested += 1
                sys.stdout.write(f"\r{Colors.BLUE}[{tested}/{total}]{Colors.RESET} Testing: {ip}:{port}     ")
                sys.stdout.flush()
                ip_port, latency = self.ping_ip(ip, port)
                if latency is not None:
                    results.append((ip_port, latency))
                time.sleep(0.02)
        
        print(f"\n\n{Colors.CYAN}═══════════════════════════════════════════════")
        print(f"Results")
        print(f"═══════════════════════════════════════════════{Colors.RESET}")
        
        if results:
            results.sort(key=lambda x: x[1])
            print(f"\n{Colors.BOLD}{Colors.GREEN}══════════ TOP 10 IPS ══════════{Colors.RESET}\n")
            print(f"{Colors.CYAN}  IP:Port                    Latency{Colors.RESET}")
            print(f"{Colors.DIM}  -----------------------  ----------{Colors.RESET}")
            for i, (ip, latency) in enumerate(results[:10], 1):
                color = Colors.GREEN if latency < 50 else Colors.YELLOW if latency < 100 else Colors.RED
                print(f"  {color}{i:02d}. {ip:<22}  {latency:>6.1f}ms{Colors.RESET}")
            print(f"\n{Colors.GREEN}✓ Copy the IPs above{Colors.RESET}")
        else:
            print(f"\n{Colors.YELLOW}⚠ No responsive IPs found.{Colors.RESET}")

def main():
    scanner = AristaScanner()
    
    while True:
        print(f"\n{Colors.CYAN}╔═══════════════════════════════════════════════╗")
        print(f"║          Arista Scanner - Main Menu            ║")
        print(f"╚═══════════════════════════════════════════════╝{Colors.RESET}")
        print(f"\n{Colors.GREEN}1.{Colors.RESET} Scan IPs {Colors.DIM}(50 IPs){Colors.RESET}")
        print(f"{Colors.GREEN}2.{Colors.RESET} Scan IPs {Colors.DIM}(100 IPs){Colors.RESET}")
        print(f"{Colors.GREEN}3.{Colors.RESET} Scan IPs {Colors.DIM}(200 IPs){Colors.RESET}")
        print(f"{Colors.GREEN}4.{Colors.RESET} Custom Count")
        print(f"\n{Colors.RED}0.{Colors.RESET} Exit")
        print()
        
        choice = input(f"{Colors.BLUE}Enter your choice: {Colors.RESET}").strip()
        
        if choice == "0":
            print(f"\n{Colors.GREEN}Goodbye!{Colors.RESET}")
            break
        elif choice == "1":
            scanner.scan(50)
        elif choice == "2":
            scanner.scan(100)
        elif choice == "3":
            scanner.scan(200)
        elif choice == "4":
            try:
                count = int(input(f"{Colors.BLUE}Enter number of IPs: {Colors.RESET}"))
                if count > 0:
                    scanner.scan(count)
                else:
                    print(f"{Colors.RED}Must be positive!{Colors.RESET}")
            except:
                print(f"{Colors.RED}Invalid number!{Colors.RESET}")
        else:
            print(f"{Colors.RED}Invalid choice!{Colors.RESET}")

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Interrupted by user{Colors.RESET}")
    except Exception as e:
        print(f"{Colors.RED}Error: {e}{Colors.RESET}")
