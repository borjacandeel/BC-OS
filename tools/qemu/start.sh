#!/usr/bin/env bash
# Arranca una imagen ARM64 de BC OS en QEMU (UEFI, virtio-gpu) para pruebas.
# Uso: tools/qemu/start.sh <imagen.img> [directorio_de_trabajo]
# Serie en serial.log, monitor en mon.sock (ver monitor.py), SSH: puerto local 2222 -> 22.
set -euo pipefail
IMG="${1:?uso: $0 <imagen.img> [dir]}"; W="${2:-$PWD}"
cd "$W"
pkill -f qemu-system-aarch64 2>/dev/null || true; sleep 1
cp /usr/share/AAVMF/AAVMF_VARS.fd vars.fd && truncate -s 64M vars.fd
cp /usr/share/AAVMF/AAVMF_CODE.fd code.fd && truncate -s 64M code.fd
rm -f mon.sock serial.log
nohup qemu-system-aarch64 -M virt -cpu cortex-a72 -m 2048 -smp 4 -display none -serial file:serial.log \
  -monitor unix:mon.sock,server,nowait -qmp unix:qmp.sock,server,nowait \
  -drive if=pflash,format=raw,readonly=on,file=code.fd -drive if=pflash,format=raw,file=vars.fd \
  -drive file="$IMG",format=raw,if=none,id=d0,snapshot=on -device virtio-blk-pci,drive=d0 \
  -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
  -device intel-hda -device hda-duplex \
  -netdev user,id=n0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=n0 > qemu.log 2>&1 &
echo "QEMU en marcha (monitor: $W/mon.sock)"
