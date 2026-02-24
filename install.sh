#!/bin/bash
#
# bashrc-config Installation Script
#

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Backup existing .bashrc if exists
if [ -f "$HOME/.bashrc" ]; then
    print_info "Backing up existing .bashrc to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp "$HOME/.bashrc" "$BACKUP_DIR/"
    print_success "Backup created"
fi

# Create symlink
print_info "Creating symlink for .bashrc"
ln -sf "$REPO_DIR/.bashrc" "$HOME/.bashrc"
print_success ".bashrc linked"

# Create components directory
mkdir -p "$HOME/.config/my_linux_config/components"

echo ""
echo "=================================================="
echo -e "${GREEN}✅ bashrc-config installed successfully${NC}"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  source ~/.bashrc"
echo ""
echo "Backup saved to: $BACKUP_DIR"
