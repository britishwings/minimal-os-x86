#!/bin/bash

# MinimalOS Quick Start Script
# Automatically builds and runs the OS with full setup

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display header
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         MinimalOS x86 - YouTube Access Quick Start             ║"
echo "║                                                                ║"
echo "║  Lightweight GUI OS with Network Support                       ║"
echo "║  Access YouTube from your host browser through QEMU           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to print section headers
print_section() {
    echo -e "${BLUE}▶ $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check prerequisites
print_section "Checking Prerequisites..."

# Check for nasm
if ! command -v nasm &> /dev/null; then
    print_error "nasm not found. Install with: sudo apt-get install nasm"
    exit 1
fi
print_success "nasm found"

# Check for make
if ! command -v make &> /dev/null; then
    print_error "make not found. Install with: sudo apt-get install make"
    exit 1
fi
print_success "make found"

# Check for qemu
if ! command -v qemu-system-i386 &> /dev/null; then
    print_error "QEMU not found. Install with: sudo apt-get install qemu-system-x86"
    exit 1
fi
print_success "qemu-system-i386 found"

echo ""

# Cleanup old builds
print_section "Cleaning Previous Build..."
make clean 2>/dev/null || true
print_success "Cleanup complete"

echo ""

# Build the OS
print_section "Building MinimalOS Image..."
make all

if [ ! -f "minimal_os.img" ]; then
    print_error "Build failed - minimal_os.img not created"
    exit 1
fi

IMAGE_SIZE=$(du -h minimal_os.img | cut -f1)
print_success "Build complete - minimal_os.img ($IMAGE_SIZE)"

echo ""

# Display options menu
print_section "Select Launch Configuration"
echo ""
echo "1) Run with Network (YouTube Access) - RECOMMENDED"
echo "2) Run Full (Network + Mouse + GUI)"
echo "3) Run Basic (GUI Only, No Network)"
echo "4) Run with Mouse Only"
echo "5) Debug Mode with Network"
echo "6) Exit"
echo ""

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        print_section "Launching MinimalOS with Network Support..."
        echo -e "${YELLOW}Tip: Open browser and navigate to: http://127.0.0.1:8080${NC}"
        echo ""
        make run-network
        ;;
    2)
        print_section "Launching MinimalOS with Full Features..."
        echo -e "${YELLOW}Features: Network + Mouse + 800x600 GUI${NC}"
        echo -e "${YELLOW}Tip: Open browser and navigate to: http://127.0.0.1:8080${NC}"
        echo ""
        make run-full
        ;;
    3)
        print_section "Launching MinimalOS (GUI Only)..."
        echo -e "${YELLOW}No network access in this mode${NC}"
        echo ""
        make run
        ;;
    4)
        print_section "Launching MinimalOS with Mouse Support..."
        echo -e "${YELLOW}Mouse enabled, Network disabled${NC}"
        echo ""
        make run-mouse
        ;;
    5)
        print_section "Launching MinimalOS in Debug Mode..."
        echo -e "${YELLOW}Connect GDB with: gdb -ex 'target remote localhost:1234' -ex 'continue'${NC}"
        echo ""
        make debug-network
        ;;
    6)
        print_success "Exiting..."
        exit 0
        ;;
    *)
        print_error "Invalid option"
        exit 1
        ;;
esac
