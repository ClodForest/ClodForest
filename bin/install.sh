#!/bin/sh
# ClaudeLink Coordinator Bootstrap Script
# Expected to be run from the root of the project repository
# Handles minimal setup, then delegates to Cake for full installation
# Compatible with POSIX sh (bash, zsh, dash, etc.)

set -eu

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
if [ ! -f "package.json" ] ||
   [ ! -f "server.js" ]; then
    error "This script must be run from the root of the ClaudeLink repository"
fi

log "Starting ClaudeLink Coordinator bootstrap..."

# Check for Node.js, offer to install via nvm if missing
if ! command -v node >/dev/null 2>&1; then
    warning "Node.js not found"

    # Check if nvm is available
    if command -v nvm >/dev/null 2>&1 ||
       [ -s "$HOME/.nvm/nvm.sh" ]; then
        log "NVM detected"
        printf "Install Node.js LTS via nvm? [y/N]: "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY])
                log "Installing Node.js LTS via nvm..."
                # Source nvm if it exists but isn't in PATH
                [ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"
                nvm install --lts
                nvm use --lts
                success "Node.js LTS installed and activated"
                ;;
            *)
                error "Node.js is required. Please install Node.js 18+ and run this script again."
                ;;
        esac
    else
        log "NVM not found"
        printf "Install nvm and Node.js LTS? [y/N]: "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY])
                log "Installing nvm..."
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

                # Source nvm for current session
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

                log "Installing Node.js LTS..."
                nvm install --lts
                nvm use --lts
                success "NVM and Node.js LTS installed"
                ;;
            *)
                error "Node.js is required. Please install Node.js 18+ manually and run this script again."
                ;;
        esac
    fi
fi

# Check Node.js version
NODE_VERSION=$(node --version | sed 's/v//')
MAJOR_VERSION=$(echo "$NODE_VERSION" | cut -d. -f1)

if [ "$MAJOR_VERSION" -lt 18 ]; then
    warning "Node.js $NODE_VERSION found, but 18+ is recommended"

    # Check if nvm is available for upgrade
    if command -v nvm >/dev/null 2>&1 ||
       [ -s "$HOME/.nvm/nvm.sh" ]; then
        printf "Upgrade to Node.js LTS via nvm? [y/N]: "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY])
                log "Upgrading to Node.js LTS..."
                # Source nvm if it exists but isn't in PATH
                [ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"
                nvm install --lts
                nvm use --lts
                success "Upgraded to Node.js LTS"
                ;;
            *)
                warning "Continuing with Node.js $NODE_VERSION (may cause issues)"
                ;;
        esac
    else
        warning "NVM not available for upgrade. Continuing with Node.js $NODE_VERSION"
    fi
else
    success "Node.js $NODE_VERSION detected"
fi

# Check for npm
if ! command -v npm >/dev/null 2>&1; then
    error "npm is required but not found"
fi

# Install dependencies
log "Installing Node.js dependencies..."
npm install
success "Dependencies installed or updated"

# Install CoffeeScript globally if not available
if ! command -v coffee >/dev/null 2>&1; then
    log "Installing CoffeeScript globally..."
    npm install -g coffeescript
    success "CoffeeScript installed globally"
else
    success "CoffeeScript already available"
fi

# Verify Cake is available
if ! command -v cake >/dev/null 2>&1; then
    error "Cake not found after CoffeeScript installation"
fi

success "Cake build tool available"

# Create Cakefile if it doesn't exist
if [ ! -f "Cakefile" ]; then
    error "Cakefile not found - did you cline the right repository?"
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
