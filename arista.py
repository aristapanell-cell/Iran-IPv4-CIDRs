#!/usr/bin/env python3

import asyncio
import json
import sys
import time
import os
import signal
import socket
import ssl
import random
import ipaddress
import heapq
import re
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass, field
import aiohttp

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

@dataclass
class TLSResult:
    success: bool = False
    tcp_latency: float = 0.0
    tls_latency: float = 0.0
    http_latency: float = 0.0
    tls_version: Optional[str] = None
    http_status: int = 0
    error: Optional[str] = None

@dataclass
class ScanResult:
    ip: str
    port: int = 443
    is_alive: bool = False
    tls_supported: bool = False
    tcp_latency: float = 0.0
    tls_latency: float = 0.0
    http_latency: float = 0.0
    score: float = 0.0
    tls_version: Optional[str] = None
    http_status: int = 0
    error: Optional[str] = None

class TLSProbe:
    def __init__(self):
        self.ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        self.ssl_context.check_hostname = False
        self.ssl_context.verify_mode = ssl.CERT_NONE
        self.ssl_context.minimum_version = ssl.TLSVersion.TLSv1_2
        self.ssl_context.maximum_version = ssl.TLSVersion.TLSv1_3
        self.ssl_context.set_ciphers(
            'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:'
            'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305'
        )
        self.ssl_context.set_alpn_protocols(['h2', 'http/1.1'])

    async def probe_full(self, host: str, port: int = 443, timeout: float = 1.5, http_check: bool = True) -> TLSResult:
        result = TLSResult()
        reader = writer = None
        
        try:
            tcp_start = time.time()
            try:
                reader, writer = await asyncio.wait_for(
                    asyncio.open_connection(host, port, ssl=False),
                    timeout=timeout
                )
                result.tcp_latency = (time.time() - tcp_start) * 1000
            except Exception as e:
                result.error = str(e)
                return result

            tls_start = time.time()
            try:
                loop = asyncio.get_event_loop()
                ssl_transport = await loop.create_connection(
                    lambda: asyncio.Protocol(),
                    host=host,
                    port=port,
                    ssl=self.ssl_context,
                    server_hostname=host,
                    sock=writer.transport.get_extra_info('socket'),
                    ssl_handshake_timeout=3.0
                )
                ssl_obj = ssl_transport[0].get_extra_info('ssl_object')
                
                if ssl_obj:
                    result.tls_version = ssl_obj.version()
                
                result.tls_latency = (time.time() - tls_start) * 1000
            except Exception as e:
                result.error = f"TLS error: {e}"
                if writer:
                    writer.close()
                    await writer.wait_closed()
                return result

            if http_check:
                http_start = time.time()
                try:
                    request = (f"HEAD / HTTP/1.1\r\nHost: {host}\r\n"
                              f"Connection: close\r\nUser-Agent: AristaScanner/1.0\r\n\r\n")
                    writer.write(request.encode())
                    await writer.drain()
                    
                    remaining = timeout - ((time.time() - tls_start) / 1000)
                    if remaining > 0:
                        response = await asyncio.wait_for(
                            reader.read(1024),
                            timeout=remaining
                        )
                        
                        if response:
                            status_line = response.split(b'\r\n')[0] if response else b''
                            match = re.search(rb'HTTP/(\d+\.\d+)\s+(\d+)', status_line)
                            if match:
                                result.http_status = int(match.group(2))
                    
                    result.http_latency = (time.time() - http_start) * 1000
                    result.success = True
                except Exception:
                    result.success = True
            else:
                result.success = True

        except Exception as e:
            result.error = str(e)
        finally:
            if writer:
                writer.close()
                try:
                    await writer.wait_closed()
                except:
                    pass

        return result

class IPGenerator:
    def __init__(self):
        self.used_ips = set()
        self.ranges = [
            {'name': 'Cloudflare Main', 'cidr': '104.16.0.0/12', 'color': Colors.CYAN, 'priority': 1},
            {'name': 'Cloudflare 2', 'cidr': '104.24.0.0/13', 'color': Colors.BLUE, 'priority': 2},
            {'name': 'Cloudflare 3', 'cidr': '141.101.0.0/16', 'color': Colors.MAGENTA, 'priority': 3},
            {'name': 'Cloudflare 4', 'cidr': '162.158.0.0/15', 'color': Colors.GREEN, 'priority': 4},
            {'name': 'Cloudflare 5', 'cidr': '172.64.0.0/13', 'color': Colors.YELLOW, 'priority': 5},
            {'name': 'AWS 1', 'cidr': '3.0.0.0/8', 'color': Colors.RED, 'priority': 6},
            {'name': 'AWS 2', 'cidr': '13.0.0.0/8', 'color': Colors.CYAN, 'priority': 7},
            {'name': 'AWS 3', 'cidr': '15.0.0.0/8', 'color': Colors.BLUE, 'priority': 8},
            {'name': 'AWS 4', 'cidr': '16.0.0.0/8', 'color': Colors.MAGENTA, 'priority': 9},
            {'name': 'AWS 5', 'cidr': '18.0.0.0/8', 'color': Colors.GREEN, 'priority': 10},
            {'name': 'AWS 6', 'cidr': '34.0.0.0/8', 'color': Colors.YELLOW, 'priority': 11},
            {'name': 'AWS 7', 'cidr': '35.0.0.0/8', 'color': Colors.RED, 'priority': 12},
            {'name': 'AWS 8', 'cidr': '44.0.0.0/8', 'color': Colors.CYAN, 'priority': 13},
            {'name': 'AWS 9', 'cidr': '50.0.0.0/8', 'color': Colors.BLUE, 'priority': 14},
            {'name': 'AWS 10', 'cidr': '52.0.0.0/8', 'color': Colors.MAGENTA, 'priority': 15},
            {'name': 'AWS 11', 'cidr': '54.0.0.0/8', 'color': Colors.GREEN, 'priority': 16},
            {'name': 'AWS 12', 'cidr': '63.0.0.0/8', 'color': Colors.YELLOW, 'priority': 17},
            {'name': 'Google 1', 'cidr': '8.0.0.0/8', 'color': Colors.RED, 'priority': 18},
            {'name': 'Google 2', 'cidr': '23.0.0.0/8', 'color': Colors.CYAN, 'priority': 19},
            {'name': 'Google 3', 'cidr': '34.0.0.0/8', 'color': Colors.BLUE, 'priority': 20},
            {'name': 'Google 4', 'cidr': '35.0.0.0/8', 'color': Colors.MAGENTA, 'priority': 21},
            {'name': 'Google 5', 'cidr': '36.0.0.0/8', 'color': Colors.GREEN, 'priority': 22},
            {'name': 'Google 6', 'cidr': '37.0.0.0/8', 'color': Colors.YELLOW, 'priority': 23},
            {'name': 'Google 7', 'cidr': '38.0.0.0/8', 'color': Colors.RED, 'priority': 24},
            {'name': 'Azure 1', 'cidr': '13.0.0.0/8', 'color': Colors.CYAN, 'priority': 25},
            {'name': 'Azure 2', 'cidr': '20.0.0.0/8', 'color': Colors.BLUE, 'priority': 26},
            {'name': 'Azure 3', 'cidr': '23.0.0.0/8', 'color': Colors.MAGENTA, 'priority': 27},
            {'name': 'Azure 4', 'cidr': '40.0.0.0/8', 'color': Colors.GREEN, 'priority': 28},
            {'name': 'Azure 5', 'cidr': '51.0.0.0/8', 'color': Colors.YELLOW, 'priority': 29},
            {'name': 'Azure 6', 'cidr': '52.0.0.0/8', 'color': Colors.RED, 'priority': 30},
            {'name': 'Azure 7', 'cidr': '65.0.0.0/8', 'color': Colors.CYAN, 'priority': 31},
            {'name': 'Azure 8', 'cidr': '70.0.0.0/8', 'color': Colors.BLUE, 'priority': 32},
            {'name': 'DigitalOcean 1', 'cidr': '46.0.0.0/8', 'color': Colors.MAGENTA, 'priority': 33},
            {'name': 'DigitalOcean 2', 'cidr': '50.0.0.0/8', 'color': Colors.GREEN, 'priority': 34},
            {'name': 'DigitalOcean 3', 'cidr': '51.0.0.0/8', 'color': Colors.YELLOW, 'priority': 35},
            {'name': 'DigitalOcean 4', 'cidr': '52.0.0.0/8', 'color': Colors.RED, 'priority': 36},
            {'name': 'Oracle 1', 'cidr': '129.0.0.0/8', 'color': Colors.CYAN, 'priority': 37},
            {'name': 'Oracle 2', 'cidr': '130.0.0.0/8', 'color': Colors.BLUE, 'priority': 38},
            {'name': 'Oracle 3', 'cidr': '131.0.0.0/8', 'color': Colors.MAGENTA, 'priority': 39},
            {'name': 'Oracle 4', 'cidr': '132.0.0.0/8', 'color': Colors.GREEN, 'priority': 40},
            {'name': 'Vultr 1', 'cidr': '45.0.0.0/8', 'color': Colors.YELLOW, 'priority': 41},
            {'name': 'Vultr 2', 'cidr': '64.0.0.0/8', 'color': Colors.RED, 'priority': 42},
            {'name': 'Vultr 3', 'cidr': '65.0.0.0/8', 'color': Colors.CYAN, 'priority': 43},
            {'name': 'Vultr 4', 'cidr': '66.0.0.0/8', 'color': Colors.BLUE, 'priority': 44}
        ]

    def _ip_to_int(self, ip: str) -> int:
        return int(ipaddress.ip_address(ip))

    def _int_to_ip(self, ip_int: int) -> str:
        return str(ipaddress.ip_address(ip_int))

    def generate_from_cidr(self, cidr: str, count: int = 100) -> List[str]:
        ips = []
        try:
            network = ipaddress.ip_network(cidr, strict=False)
            total_ips = network.num_addresses
            if total_ips <= 1:
                return ips
            
            start_ip = int(network.network_address)
            end_ip = int(network.broadcast_address)
            
            attempts = 0
            while len(ips) < count and attempts < count * 20:
                attempts += 1
                ip_int = random.randint(start_ip + 1, end_ip - 1)
                ip = self._int_to_ip(ip_int)
                if ip_int not in self.used_ips:
                    self.used_ips.add(ip_int)
                    ips.append(ip)
        except Exception as e:
            pass
        return ips

    def generate_from_range(self, start: str, end: str, count: int = 100) -> List[str]:
        ips = []
        try:
            start_int = self._ip_to_int(start)
            end_int = self._ip_to_int(end)
            if start_int >= end_int:
                return ips
            attempts = 0
            while len(ips) < count and attempts < count * 10:
                attempts += 1
                ip_int = random.randint(start_int, end_int)
                ip = self._int_to_ip(ip_int)
                if ip_int not in self.used_ips:
                    self.used_ips.add(ip_int)
                    ips.append(ip)
        except:
            pass
        return ips

    def generate(self, count: int = 100) -> List[str]:
        ips = []
        for r in self.ranges:
            ips.extend(self.generate_from_cidr(r['cidr'], count // len(self.ranges) + 1))
        return ips[:count]

    def get_range_by_index(self, index: int) -> Optional[Dict]:
        if 0 <= index < len(self.ranges):
            return self.ranges[index]
        return None

class AristaScanner:
    def __init__(self, max_concurrent: int = 500, timeout: int = 1):
        self.max_concurrent = max_concurrent
        self.timeout = timeout
        self.best_results = []
        self.alive_count = 0
        self.total_scanned = 0
        self.tls = TLSProbe()
        self.ip_gen = IPGenerator()
        self.running = True
        self.start_time = None

    def calculate_score(self, r: ScanResult) -> float:
        score = 0.0
        if not r.is_alive:
            return 0.0
        
        latency = r.tcp_latency + r.tls_latency + r.http_latency
        
        if latency > 0:
            if latency < 50: score += 40
            elif latency < 100: score += 30
            elif latency < 200: score += 20
            elif latency < 500: score += 10
        
        if 200 <= r.http_status < 300: score += 40
        elif 300 <= r.http_status < 400: score += 30
        elif 400 <= r.http_status < 500: score += 10
        
        if r.tls_version and 'TLSv1.3' in r.tls_version: score += 20
        elif r.tls_version and 'TLSv1.2' in r.tls_version: score += 10
        
        return min(score, 100.0)

    async def scan_ip(self, ip: str, port: int = 443) -> ScanResult:
        result = ScanResult(ip=ip, port=port)
        
        tls_result = await self.tls.probe_full(ip, port, timeout=self.timeout)
        
        if tls_result.success:
            result.is_alive = True
            result.tls_supported = True
            result.tcp_latency = tls_result.tcp_latency
            result.tls_latency = tls_result.tls_latency
            result.http_latency = tls_result.http_latency
            result.tls_version = tls_result.tls_version
            result.http_status = tls_result.http_status
            
            result.score = self.calculate_score(result)
            self.alive_count += 1
        else:
            result.error = tls_result.error
        
        return result

    def print_menu(self):
        print(f"\n{Colors.CYAN}╔══════════════════════════════════════════════════════════╗")
        print(f"║              Arista Scanner - Select Range            ║")
        print(f"╚══════════════════════════════════════════════════════════╝{Colors.RESET}")
        print(f"\n{Colors.DIM}Select a range to scan:{Colors.RESET}\n")
        
        ranges = self.ip_gen.ranges
        for i, r in enumerate(ranges, 1):
            color = r['color']
            num = f"{i:02d}"
            priority_star = "⭐ " if r.get('priority', 0) <= 5 else "   "
            print(f"  {color}{num}{Colors.RESET}. {priority_star}{color}{r['name']}{Colors.RESET} {Colors.DIM}({r['cidr']}){Colors.RESET}")
            if i % 10 == 0 and i < len(ranges):
                print()
        
        print(f"\n  {Colors.RED}00{Colors.RESET}. {Colors.RED}Exit{Colors.RESET}")
        print(f"\n{Colors.GREEN}╔══════════════════════════════════════════════════════════╗")
        print(f"║  {Colors.DIM}Enter number (01-44) to select range or 00 to exit{Colors.GREEN}  ║")
        print(f"║  {Colors.DIM}⭐ = Recommended ranges (Cloudflare){Colors.GREEN}              ║")
        print(f"╚══════════════════════════════════════════════════════════╝{Colors.RESET}")

    def print_scan_menu(self):
        print(f"\n{Colors.CYAN}╔══════════════════════════════════════════════════════════╗")
        print(f"║              Arista Scanner - Scan Options              ║")
        print(f"╚══════════════════════════════════════════════════════════╝{Colors.RESET}")
        print(f"\n{Colors.GREEN}1.{Colors.RESET} Fast Scan {Colors.DIM}(50 IPs){Colors.RESET}")
        print(f"{Colors.GREEN}2.{Colors.RESET} Normal Scan {Colors.DIM}(100 IPs){Colors.RESET}")
        print(f"{Colors.GREEN}3.{Colors.RESET} Deep Scan {Colors.DIM}(500 IPs){Colors.RESET}")
        print(f"{Colors.GREEN}4.{Colors.RESET} Extreme Scan {Colors.DIM}(1000 IPs){Colors.RESET}")
        print(f"{Colors.GREEN}5.{Colors.RESET} Custom Count")
        print(f"\n{Colors.RED}0.{Colors.RESET} Back to Range Selection")
        print()

    async def scan(self, ips: List[str], port: int = 443, show_progress: bool = True):
        if not ips:
            print(f"{Colors.RED}No IPs to scan{Colors.RESET}")
            return

        self.total_scanned = 0
        self.alive_count = 0
        self.best_results = []
        self.running = True
        self.start_time = time.time()
        
        print(f"\n{Colors.CYAN}╔═══════════════════════════════════════════════╗")
        print(f"║      Arista Scanner - Starting Scan         ║")
        print(f"╚═══════════════════════════════════════════════╝{Colors.RESET}")
        print(f"\n{Colors.BLUE}[*]{Colors.RESET} Targets: {len(ips)} IPs")
        print(f"{Colors.BLUE}[*]{Colors.RESET} Port: {port}")
        print(f"{Colors.BLUE}[*]{Colors.RESET} Concurrent: {self.max_concurrent}")
        print(f"{Colors.BLUE}[*]{Colors.RESET} Timeout: {self.timeout}s\n")

        semaphore = asyncio.Semaphore(self.max_concurrent)

        async def scan_one(ip: str):
            if not self.running:
                return
            async with semaphore:
                result = await self.scan_ip(ip, port)
                self.total_scanned += 1
                
                if result.is_alive and result.score > 0:
                    if len(self.best_results) < 20:
                        heapq.heappush(self.best_results, (result.score, result))
                    else:
                        heapq.heapreplace(self.best_results, (result.score, result))
                
                if show_progress and (self.total_scanned % 50 == 0 or self.total_scanned == len(ips)):
                    elapsed = time.time() - self.start_time
                    rate = self.total_scanned / elapsed if elapsed > 0 else 0
                    print(f"\r{Colors.BLUE}[{self.total_scanned}/{len(ips)}]{Colors.RESET} "
                          f"Alive: {Colors.GREEN}{self.alive_count}{Colors.RESET} "
                          f"Rate: {rate:.1f}/s", end="")

        tasks = []
        for ip in ips:
            if not self.running:
                break
            tasks.append(asyncio.create_task(scan_one(ip)))
        
        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)

        elapsed = time.time() - self.start_time
        print(f"\n\n{Colors.CYAN}═══════════════════════════════════════════════")
        print(f"Scan Summary")
        print(f"═══════════════════════════════════════════════{Colors.RESET}")
        print(f"{Colors.BLUE}[*]{Colors.RESET} Total scanned: {self.total_scanned}")
        print(f"{Colors.GREEN}[+]{Colors.RESET} Alive: {self.alive_count}")
        if self.total_scanned > 0:
            print(f"{Colors.YELLOW}[*]{Colors.RESET} Success rate: {(self.alive_count/self.total_scanned*100):.1f}%")
        print(f"{Colors.BLUE}[*]{Colors.RESET} Time: {elapsed:.1f}s")
        if elapsed > 0:
            print(f"{Colors.BLUE}[*]{Colors.RESET} Rate: {self.total_scanned/elapsed:.1f} IPs/s\n")
        
        if self.best_results:
            sorted_results = sorted(self.best_results, key=lambda x: x[0], reverse=True)
            print(f"\n{Colors.BOLD}{Colors.GREEN}══════════ TOP 20 IPS ══════════{Colors.RESET}\n")
            for i, (score, r) in enumerate(sorted_results[:20], 1):
                color = (
                    Colors.GREEN if score >= 80 else
                    Colors.YELLOW if score >= 60 else
                    Colors.CYAN
                )
                print(
                    f"{color}{i:02d}{Colors.RESET} "
                    f"{Colors.BOLD}{r.ip}{Colors.RESET}"
                    f":{r.port} "
                    f"[{score:.1f}] "
                    f"{r.tls_version or ''} "
                    f"{r.http_status}"
                )
            print(f"\n{Colors.GREEN}✓ Copy the IPs above{Colors.RESET}")
        else:
            print(f"\n{Colors.YELLOW}⚠ No alive IPs found in this range.{Colors.RESET}")
            print(f"{Colors.DIM}Try increasing the number of IPs or selecting a different range.{Colors.RESET}")

async def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Arista Scanner')
    parser.add_argument('--range', '-r', type=int, help='Range number to scan')
    parser.add_argument('--count', '-n', type=int, default=100, help='Number of IPs to scan')
    parser.add_argument('--port', '-p', type=int, default=443, help='Port to scan')
    parser.add_argument('--concurrent', '-C', type=int, default=500, help='Max concurrent connections')
    parser.add_argument('--timeout', '-t', type=float, default=1.5, help='Timeout in seconds')
    parser.add_argument('--quiet', '-q', action='store_true', help='Quiet mode')
    
    args = parser.parse_args()
    
    scanner = AristaScanner(max_concurrent=args.concurrent, timeout=args.timeout)
    
    if args.range is not None:
        r = scanner.ip_gen.get_range_by_index(args.range - 1)
        if r:
            ips = scanner.ip_gen.generate_from_cidr(r['cidr'], args.count)
            if ips:
                await scanner.scan(ips, port=args.port, show_progress=not args.quiet)
        return
    
    while True:
        scanner.print_menu()
        choice = input(f"\n{Colors.BLUE}Enter your choice: {Colors.RESET}").strip()
        
        if choice == "00" or choice == "0":
            print(f"\n{Colors.GREEN}Goodbye!{Colors.RESET}")
            break
        
        try:
            idx = int(choice) - 1
            r = scanner.ip_gen.get_range_by_index(idx)
            if not r:
                print(f"{Colors.RED}Invalid range number!{Colors.RESET}")
                continue
            
            print(f"\n{Colors.GREEN}Selected: {r['name']} ({r['cidr']}){Colors.RESET}")
            
            while True:
                scanner.print_scan_menu()
                scan_choice = input(f"{Colors.BLUE}Choose scan type: {Colors.RESET}").strip()
                
                if scan_choice == "0":
                    break
                
                count_map = {
                    "1": 50,
                    "2": 100,
                    "3": 500,
                    "4": 1000
                }
                
                if scan_choice in count_map:
                    count = count_map[scan_choice]
                elif scan_choice == "5":
                    count_input = input(f"{Colors.BLUE}Enter number of IPs to scan: {Colors.RESET}")
                    try:
                        count = int(count_input)
                        if count <= 0:
                            print(f"{Colors.RED}Count must be positive!{Colors.RESET}")
                            continue
                    except:
                        print(f"{Colors.RED}Invalid number!{Colors.RESET}")
                        continue
                else:
                    print(f"{Colors.RED}Invalid choice!{Colors.RESET}")
                    continue
                
                ips = scanner.ip_gen.generate_from_cidr(r['cidr'], count)
                if ips:
                    await scanner.scan(ips, port=args.port, show_progress=not args.quiet)
                else:
                    print(f"{Colors.RED}No IPs generated!{Colors.RESET}")
                
                break
                
        except ValueError:
            print(f"{Colors.RED}Invalid input! Please enter a number.{Colors.RESET}")

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Interrupted by user{Colors.RESET}")
    except Exception as e:
        print(f"{Colors.RED}Error: {e}{Colors.RESET}")
