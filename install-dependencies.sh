#!/bin/bash
# Install shared library dependencies for Indigo

set -e  # Exit on any error

echo "Installing dependencies (zlib, tinyxml) as shared libraries..."

# Create directory structure
mkdir -p indigo-install/lib

# Check if dependencies are already installed
if [ -f "indigo-install/lib/libz.so.1" ] && [ -f "indigo-install/lib/libtinyxml.so.2.6.2" ]; then
    echo "Dependencies already installed, skipping download and extraction."
    echo "To reinstall, remove the indigo-install directory first."
    exit 0
fi

cd indigo-install

# Download and extract dependency packages
echo "Downloading dependency packages..."
mkdir -p downloads
cd downloads

# Download zlib1g package (provides libz.so.1)
echo "Installing zlib..."
ZLIB_URL="http://archive.ubuntu.com/ubuntu/pool/main/z/zlib/zlib1g_1.2.11.dfsg-2ubuntu1_amd64.deb"
if wget -q "$ZLIB_URL" 2>/dev/null || curl -s -O "$ZLIB_URL" 2>/dev/null; then
    ZLIB_FILE=$(basename "$ZLIB_URL")
    dpkg-deb -x "$ZLIB_FILE" ./zlib-extracted/
    find zlib-extracted -name "libz.so*" -exec cp -P {} ../lib/ \;
    echo "zlib installed"
else
    echo "Warning: Could not download zlib package"
fi

# Download libtinyxml package (provides libtinyxml.so.2.6.2)
echo "Installing TinyXML..."
TINYXML_URL="http://archive.ubuntu.com/ubuntu/pool/universe/t/tinyxml/libtinyxml2.6.2v5_2.6.2-4_amd64.deb"
if wget -q "$TINYXML_URL" 2>/dev/null || curl -s -O "$TINYXML_URL" 2>/dev/null; then
    TINYXML_FILE=$(basename "$TINYXML_URL")
    dpkg-deb -x "$TINYXML_FILE" ./tinyxml-extracted/
    find tinyxml-extracted -name "libtinyxml.so*" -exec cp -P {} ../lib/ \;
    echo "TinyXML installed"
else
    echo "Warning: Could not download tinyxml package"
fi

# Download libstdc++6 package (provides libstdc++.so.6)
# Note: libstdc++ is usually available system-wide, but we bundle it for completeness
echo "Installing libstdc++..."
LIBSTDCXX_URL="http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-12/libstdc++6_12.3.0-1ubuntu1~22.04.3_amd64.deb"
if wget -q "$LIBSTDCXX_URL" 2>/dev/null || curl -s -O "$LIBSTDCXX_URL" 2>/dev/null; then
    LIBSTDCXX_FILE=$(basename "$LIBSTDCXX_URL")
    dpkg-deb -x "$LIBSTDCXX_FILE" ./libstdcxx-extracted/
    find libstdcxx-extracted -name "libstdc++.so*" -exec cp -P {} ../lib/ \;
    echo "libstdc++ installed"
else
    echo "Warning: Could not download libstdc++ package"
fi

# Cleanup
cd ..
rm -rf downloads

echo "Dependencies successfully installed to ./indigo-install/lib/"
echo ""
echo "Installed files:"
ls -la lib/
