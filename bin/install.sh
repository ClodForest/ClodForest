#!/bin/bash
# ClaudeLink Coordinator Bootstrap Script
# Expected to be run from the root of the project repository
# Handles minimal setup, then delegates to Cake for full installation

set -euo pipefail

PROJECT_ROOT="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[ClaudeLink Bootstrap]${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
    exit 1
}

# Verify we're in the project root
if [[ ! -f "package.json" ]] ||
   [[ ! -f "server.coffee" ]]; then
    error "This script must be run from the root of the ClaudeLink repository"
fi

log "Starting ClaudeLink Coordinator bootstrap..."

# Check for Node.js
if ! command -v node &> /dev/null; then
    error "Node.js is required but not installed. Please install Node.js 18+ first."
fi

NODE_VERSION=$(node --version | sed 's/v//')
MAJOR_VERSION=$(echo "$NODE_VERSION" | cut -d. -f1)

if [[ $MAJOR_VERSION -lt 18 ]]; then
    error "Node.js 18+ is required. Current version: $NODE_VERSION"
fi

success "Node.js $NODE_VERSION detected"

# Check for npm
if ! command -v npm &> /dev/null; then
    error "npm is required but not found"
fi

# Install dependencies if needed
if [[ ! -d "node_modules" ]]; then
    log "Installing Node.js dependencies..."
    npm install
    success "Dependencies installed"
else
    log "Dependencies already installed"
fi

# Install CoffeeScript globally if not available
if ! command -v coffee &> /dev/null; then
    log "Installing CoffeeScript globally..."
    npm install -g coffeescript
    success "CoffeeScript installed globally"
else
    success "CoffeeScript already available"
fi

# Verify Cake is available
if ! command -v cake &> /dev/null; then
    error "Cake not found after CoffeeScript installation"
fi

success "Cake build tool available"

# Create Cakefile if it doesn't exist
if [[ ! -f "Cakefile" ]]; then
    warning "Cakefile not found - will be created by build process"
fi

# Run Cake to finish installation
log "Delegating to Cake for full installation..."
echo

if cake build; then
    echo
    success "ClaudeLink Coordinator installation complete!"
    echo
    log "Next steps:"
    echo "  1. Review configuration in package.json"
    echo "  2. Start development server: cake dev"
    echo "  3. Or start production server: cake start"
    echo "  4. Visit http://localhost:8080 to verify installation"
    echo
else
    error "Cake build failed. Check output above for details."
fi
