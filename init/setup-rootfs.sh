#!/bin/sh
ROOT="$1"
if [ -z "$ROOT" ]; then
    echo "Usage: $0 /path/to/rootfs"
    exit 1
fi
set -e
ALPINE_VER="3.21.7"
ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/alpine-minirootfs-${ALPINE_VER}-x86_64.tar.gz"
rm -rf "$ROOT"
mkdir -p "$ROOT"
echo "[1] Downloading Alpine minirootfs $ALPINE_VER..."
wget -q -O /tmp/minirootfs.tar.gz "$ALPINE_URL"
tar xzf /tmp/minirootfs.tar.gz -C "$ROOT"
rm -f /tmp/minirootfs.tar.gz
echo "[2] Removing OpenRC..."
"$ROOT/sbin/apk" --root "$ROOT" del openrc 2>/dev/null || true
echo "[3] Setting up fastfetch..."
FASTFETCH_URL="https://github.com/fastfetch-cli/fastfetch/releases/download/2.15.0/fastfetch-linux-amd64.tar.gz"
wget -q -O /tmp/ff.tar.gz "$FASTFETCH_URL"
tar xzf /tmp/ff.tar.gz -C "$ROOT/usr/bin/" --strip-components=3 \
    "fastfetch-linux-amd64/usr/bin/fastfetch" 2>/dev/null || true
chmod +x "$ROOT/usr/bin/fastfetch" 2>/dev/null || true
rm -f /tmp/ff.tar.gz
echo "[4] Glibc for fastfetch..."
if [ -f "$ROOT/usr/bin/fastfetch" ]; then
    mkdir -p "$ROOT/lib64" "$ROOT/usr/lib"
    ln -sf /usr/lib/ld-linux-x86-64.so.2 "$ROOT/lib64/ld-linux-x86-64.so.2" 2>/dev/null || true
    for lib in libc.so.6 libm.so.6 libdl.so.2 libpthread.so.0; do
        cp /usr/lib/$lib "$ROOT/usr/lib/" 2>/dev/null || true
    done
    cp /usr/lib/ld-linux-x86-64.so.2 "$ROOT/usr/lib/" 2>/dev/null || true
fi
echo "[5] Config files..."
cat > "$ROOT/etc/profile" << 'PROFILE'
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export EDITOR=vi
export PS1='alpinedos:\w\$ '
PROFILE
cat > "$ROOT/etc/os-release" << 'EOF'
NAME="alpinedos"
ID=alpinedos
PRETTY_NAME="alpinedos - Alpine with custom asm init"
HOME_URL="https://github.com/sir/alpinedos"
EOF
echo "alpinedos" > "$ROOT/etc/hostname"
echo ""
echo "=== Rootfs ready ==="
echo "Size: $(du -sh "$ROOT" | cut -f1)"
echo "apk: $(ls -la "$ROOT/sbin/apk" | awk '{print $NF}')"
echo "Packages: $("$ROOT/sbin/apk" --root "$ROOT" list 2>/dev/null | wc -l)" || true
