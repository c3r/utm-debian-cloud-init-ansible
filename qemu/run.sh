#!/usr/bin/env bash
set -euo pipefail

NAME="$1"
DISK="$2"
SEED="$3"

qemu-system-aarch64 \
  -machine virt \
  -cpu host \
  -m 2048 \
  -smp 2 \
  -drive file="$DISK",if=virtio \
  -drive file="$SEED",if=virtio,media=cdrom \
  -netdev vmnet-bridged,id=net0,ifname=en0 \
  -device virtio-net-pci,netdev=net0

# (Use vmnet-shared if bridged is not allowed.)