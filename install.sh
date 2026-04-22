#!/bin/bash
# install.sh - One-command installation for cl-indigo

set -e  # Exit on error

# Platform argument (required)
PLATFORM="${1:-}"
if [ -z "$PLATFORM" ]; then
    echo "Usage: $0 <platform>"
    echo "Available platforms: linux-x86_64"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the repository root
cd "$SCRIPT_DIR"

echo "=== Installing cl-indigo ==="
echo "Platform: $PLATFORM"
echo "Working directory: $(pwd)"
echo ""

echo "Step 1/2: Installing dependencies (zlib, TinyXML)..."
bash ./install-dependencies.sh

echo ""
echo "Step 2/2: Installing Indigo library..."
bash ./install-indigo.sh "$PLATFORM"

echo ""
echo "=== Installation complete! ==="
echo ""
echo "To use in SBCL:"
echo "  export LD_LIBRARY_PATH=\"$SCRIPT_DIR/indigo-install/lib:\$LD_LIBRARY_PATH\""
echo "  sbcl --eval '(push #p\"$SCRIPT_DIR/\" asdf:*central-registry*)' --eval '(asdf:load-system :cl-indigo)'"
echo ""
echo "Optional: Run './verify-install.sh' to test the installation"
