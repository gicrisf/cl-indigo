#!/bin/bash
# Install shared library dependencies for Indigo
# Note: libstdc++ is provided by nix shell (GLIBCXX_3.4.32+)

set -e

echo "Installing dependencies (zlib, tinyxml) as shared libraries..."

mkdir -p indigo-install/lib

if [ -f "indigo-install/lib/libz.so.1" ] && [ -f "indigo-install/lib/libtinyxml.so.2.6.2" ]; then
    echo "Dependencies already installed."
    exit 0
fi

cd indigo-install
mkdir -p downloads
cd downloads

echo "Installing zlib..."
ZLIB_URL="http://archive.ubuntu.com/ubuntu/pool/main/z/zlib/zlib1g_1.2.11.dfsg-2ubuntu1_amd64.deb"
if wget -q "$ZLIB_URL" 2>/dev/null || curl -s -O "$ZLIB_URL" 2>/dev/null; then
    dpkg-deb -x $(basename "$ZLIB_URL") ./zlib-extracted/
    find zlib-extracted -name "libz.so*" -exec cp -P {} ../lib/ \;
    echo "zlib installed"
fi

echo "Installing TinyXML..."
TINYXML_URL="http://archive.ubuntu.com/ubuntu/pool/universe/t/tinyxml/libtinyxml2.6.2v5_2.6.2-4_amd64.deb"
if wget -q "$TINYXML_URL" 2>/dev/null || curl -s -O "$TINYXML_URL" 2>/dev/null; then
    dpkg-deb -x $(basename "$TINYXML_URL") ./tinyxml-extracted/
    find tinyxml-extracted -name "libtinyxml.so*" -exec cp -P {} ../lib/ \;
    echo "TinyXML installed"
fi

cd ..
rm -rf downloads
echo "Done. Installed to ./indigo-install/lib/"
