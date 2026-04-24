#!/bin/bash
# install-indigo.sh - Download Indigo shared libraries for CFFI

set -e  # Exit on any error

# Platform argument (required)
PLATFORM="${1:-}"
if [ -z "$PLATFORM" ]; then
    echo "Usage: $0 <platform>"
    echo "Available platforms: linux-x86_64"
    exit 1
fi

# Validate platform
case "$PLATFORM" in
    linux-x86_64)
        # Using same version as emacs-indigo for consistency
        DEB_URL="http://archive.ubuntu.com/ubuntu/pool/universe/i/indigo/libindigo0d_1.2.3-3.1build1_amd64.deb"
        ;;
    *)
        echo "Error: Unsupported platform '$PLATFORM'"
        echo "Available platforms: linux-x86_64"
        exit 1
        ;;
esac

echo "Installing Indigo cheminformatics library for $PLATFORM..."

# Create directory structure
mkdir -p indigo-install/{include,lib}

# Check if Indigo is already installed
if [ -n "$(ls -A indigo-install/lib/ 2>/dev/null)" ] && [ -n "$(ls -A indigo-install/include/ 2>/dev/null)" ]; then
    echo "Indigo already installed, skipping download."
    echo "To reinstall, remove the indigo-install directory first."
    exit 0
fi

cd indigo-install

# Try downloading Ubuntu .deb package
echo "Downloading from: $DEB_URL"
mkdir -p downloads
cd downloads

if wget -q "$DEB_URL" 2>/dev/null || curl -s -O "$DEB_URL" 2>/dev/null; then
    DEB_FILE=$(basename "$DEB_URL")
    echo "Downloaded $DEB_FILE, extracting..."

    # Extract .deb package using dpkg-deb (handles all compression formats)
    echo "Extracting .deb package..."
    dpkg-deb -x "$DEB_FILE" ./extracted/

    # Copy files from extracted directory - shared libraries for CFFI
    if [ -d "extracted/usr/lib" ]; then
        cp extracted/usr/lib/libindigo*.so* ../lib/ 2>/dev/null || true
    fi
    # Check architecture-specific lib directories
    if [ -d "extracted/usr/lib/x86_64-linux-gnu" ]; then
        cp extracted/usr/lib/x86_64-linux-gnu/libindigo*.so* ../lib/ 2>/dev/null || true
    fi
    if [ -d "extracted/usr/include" ]; then
        cp extracted/usr/include/indigo*.h ../include/ 2>/dev/null || true
    fi

    # Create symlink for renderer library if needed
    if [ -f "../lib/libindigo-renderer.so.0d" ] && [ ! -e "../lib/libindigo-renderer.so" ]; then
        ln -sf libindigo-renderer.so.0d ../lib/libindigo-renderer.so
    fi

    # Verify files were copied
    if [ ! -f "../include/indigo.h" ] || [ -z "$(ls ../lib/libindigo*.so* 2>/dev/null)" ]; then
        echo "Error: Failed to extract Indigo files from .deb package"
        cd ../..
        exit 1
    fi

    echo "Successfully extracted from .deb package"
    cd ..
    rm -rf downloads
else
    cd ..
    rm -rf downloads
    echo "Error: Could not download Indigo .deb package"
    echo "Please manually install Indigo and place headers in ./indigo-install/include/"
    echo "and libraries in ./indigo-install/lib/"
    echo ""
    echo "On Ubuntu/Debian, you can install with:"
    echo "  sudo apt-get install libindigo0d libindigo-dev"
    echo "Then copy files from system locations to this directory."
    exit 1
fi

echo "Indigo successfully installed to ./indigo-install/"
echo "Headers: ./indigo-install/include/"
echo "Libraries: ./indigo-install/lib/"

# List what was installed
echo ""
echo "Installed files:"
echo "Headers:"
ls -la include/ 2>/dev/null || echo "No headers found"
echo ""
echo "Libraries:"
ls -la lib/ 2>/dev/null || echo "No libraries found"
