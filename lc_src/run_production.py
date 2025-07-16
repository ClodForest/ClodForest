#!/usr/bin/env python3
"""
Production deployment script for ClodForest OAuth2 + MCP servers
Runs both OAuth proxy and MCP server with proper configuration
"""

import subprocess
import sys
import time
import signal
import os
from pathlib import Path

def start_mcp_server():
    """Start the MCP server on port 8080"""
    print("Starting MCP server on port 8080...")
    mcp_script = Path(__file__).parent / "clodforest_mcp_http.py"
    return subprocess.Popen([
        sys.executable, str(mcp_script)
    ], env={**os.environ, "PYTHONPATH": str(Path(__file__).parent)})

def start_oauth_server():
    """Start the OAuth DCR server on port 8000"""
    print("Starting OAuth DCR server on port 8000...")
    oauth_script = Path(__file__).parent / "oauth_dcr_server.py"
    return subprocess.Popen([
        sys.executable, str(oauth_script)
    ], env={**os.environ, "PYTHONPATH": str(Path(__file__).parent)})

def main():
    """Start both servers and handle graceful shutdown"""
    processes = []
    
    try:
        # Start MCP server first
        mcp_process = start_mcp_server()
        processes.append(mcp_process)
        
        # Wait a moment for MCP server to start
        time.sleep(2)
        
        # Start OAuth server
        oauth_process = start_oauth_server()
        processes.append(oauth_process)
        
        print("\n" + "="*60)
        print("ClodForest OAuth2 + MCP Servers Running")
        print("="*60)
        print(f"OAuth Discovery: http://localhost:8000/.well-known/oauth-authorization-server")
        print(f"Client Registration: http://localhost:8000/register")
        print(f"MCP Endpoint (OAuth protected): http://localhost:8000/mcp")
        print(f"Direct MCP (local only): http://localhost:8080/mcp")
        print(f"Health Check: http://localhost:8000/health")
        print("="*60)
        print("Press Ctrl+C to stop both servers")
        print()
        
        # Wait for processes
        while True:
            for process in processes:
                if process.poll() is not None:
                    print(f"Process {process.pid} exited unexpectedly")
                    return 1
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\nShutting down servers...")
        
    finally:
        # Clean shutdown
        for process in processes:
            if process.poll() is None:
                print(f"Terminating process {process.pid}")
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    print(f"Force killing process {process.pid}")
                    process.kill()
        
        print("All servers stopped.")
        return 0

if __name__ == "__main__":
    sys.exit(main())
