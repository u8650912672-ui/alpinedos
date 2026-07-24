#!/bin/sh
set -e
ROOTFS="/tmp/alpinetest"
INIT_BINARY="$PWD/init"
ISO_OUTPUT="/tmp/alpinedos.iso"
echo "[1/5] attampting to build"
make -s -C "$PWD"
echo "[2/5] Creating alpine rootfs..."
sh "$PWD/setup-rootfs.sh" "$ROOTFS"
echo "[3/5] Copying init as /sbin/init..."
rm -f "$ROOTFS/sbin/init"
cp "$INIT_BINARY" "$ROOTFS/sbin/init"
chmod +x "$ROOTFS/sbin/init"
echo "[4/5] Creating initramfs..."
cp "$ROOTFS/sbin/init" "$ROOTFS/init"
cd "$ROOTFS"
find . | cpio -o -H newc | gzip > /tmp/alpinedos-initrd.gz
echo "[5/5] Building the iso..."
mkdir -p /tmp/isobuild/boot/grub
cp /tmp/alpinedos-initrd.gz /tmp/isobuild/boot/initrd
if [ -f "$ROOTFS/boot/vmlinuz-lts" ]; then
    cp "$ROOTFS/boot/vmlinuz-lts" /tmp/isobuild/boot/vmlinuz
elif [ -f /boot/vmlinuz-linux ]; then
    cp /boot/vmlinuz-linux /tmp/isobuild/boot/vmlinuz
else
    echo "ERROR: no kernel found!"
    exit 1
fi
cat > /tmp/isobuild/boot/grub/grub.cfg << 'GRUB'
set timeout=5
menuentry "alpinedos" {
  linux /boot/vmlinuz console=tty0 quiet
  initrd /boot/initrd
}
GRUB
grub-mkrescue -o "$ISO_OUTPUT" /tmp/isobuild 2>&1

