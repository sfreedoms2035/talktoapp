#!/usr/bin/env python3
"""
Test script to diagnose network connectivity issues with the RunPod service
"""

import socket
import requests
import time
import subprocess
import sys

def test_local_network():
    """Test local network configuration"""
    print("=== Local Network Configuration ===")
    
    # Get hostname and IP
    hostname = socket.gethostname()
    try:
        local_ip = socket.gethostbyname(hostname)
        print(f"Hostname: {hostname}")
        print(f"Local IP: {local_ip}")
    except Exception as e:
        print(f"Error getting local IP: {e}")
    
    # Get all IP addresses
    try:
        import netifaces
        interfaces = netifaces.interfaces()
        print(f"Network interfaces: {interfaces}")
        for interface in interfaces:
            addrs = netifaces.ifaddresses(interface)
            if netifaces.AF_INET in addrs:
                print(f"  {interface}: {addrs[netifaces.AF_INET]}")
    except ImportError:
        print("netifaces not available, skipping detailed interface info")
    
    print()

def test_port_binding():
    """Test if port 8000 is actually bound"""
    print("=== Port Binding Test ===")
    
    try:
        # Check what's listening on port 8000
        result = subprocess.run(['netstat', '-tuln'], capture_output=True, text=True)
        lines = result.stdout.split('\n')
        port_8000_lines = [line for line in lines if ':8000' in line]
        
        if port_8000_lines:
            print("Services listening on port 8000:")
            for line in port_8000_lines:
                print(f"  {line}")
        else:
            print("No services found listening on port 8000")
    except Exception as e:
        print(f"Error checking port binding: {e}")
    
    print()

def test_local_connection():
    """Test local connection to the service"""
    print("=== Local Connection Test ===")
    
    try:
        response = requests.get('http://localhost:8000/health', timeout=5)
        print(f"Local connection successful!")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
    except requests.exceptions.RequestException as e:
        print(f"Local connection failed: {e}")
    except Exception as e:
        print(f"Error during local connection test: {e}")
    
    print()

def test_internal_connection():
    """Test connection using internal IP"""
    print("=== Internal IP Connection Test ===")
    
    try:
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)
        
        response = requests.get(f'http://{local_ip}:8000/health', timeout=5)
        print(f"Internal IP connection successful!")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
    except requests.exceptions.RequestException as e:
        print(f"Internal IP connection failed: {e}")
    except Exception as e:
        print(f"Error during internal IP connection test: {e}")
    
    print()

def test_external_accessibility():
    """Test if the service is accessible from external IPs"""
    print("=== External Accessibility Test ===")
    
    # Try to get public IP
    try:
        public_ip = requests.get('https://api.ipify.org', timeout=5).text
        print(f"Public IP: {public_ip}")
    except Exception as e:
        print(f"Could not determine public IP: {e}")
        return
    
    print("To test external accessibility, try accessing this URL from another machine:")
    print(f"  http://{public_ip}:8000/health")
    print()
    print("If this doesn't work, the issue is likely:")
    print("1. Port 8000 is not exposed/mapped in Docker/RunPod configuration")
    print("2. Firewall is blocking the connection")
    print("3. Network security groups are not configured properly")
    print()

def main():
    """Main test function"""
    print("RunPod Service Network Diagnostic Tool")
    print("=" * 50)
    print()
    
    test_local_network()
    test_port_binding()
    test_local_connection()
    test_internal_connection()
    test_external_accessibility()
    
    print("=== Diagnostic Complete ===")
    print()
    print("Next steps:")
    print("1. Check RunPod/Docker configuration to ensure port 8000 is exposed")
    print("2. Verify firewall settings allow connections on port 8000")
    print("3. If using cloud services, check security group rules")

if __name__ == "__main__":
    main()
