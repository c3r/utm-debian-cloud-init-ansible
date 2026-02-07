#!/usr/bin/env bash
set -euo pipefail

NAME="$1"
DISK="$2"
SEED="$3"

NET_MODE="${NET_MODE:-bridged}"
NET_IF="${NET_IF:-en0}"
NET_IF="${NET_IF//\"/}"

SSH_PORT=""
VM_MAC=""
case "$NAME" in
  jumpbox)
    SSH_PORT="2222"
    VM_MAC="52:54:00:12:34:10"
    ;;
  node0)
    SSH_PORT="2223"
    VM_MAC="52:54:00:12:34:11"
    ;;
  node1)
    SSH_PORT="2224"
    VM_MAC="52:54:00:12:34:12"
    ;;
  server)
    SSH_PORT="2225"
    VM_MAC="52:54:00:12:34:20"
    ;;
  *)
    SSH_PORT="2222"
    VM_MAC="52:54:00:12:34:99"
    ;;
esac

if [ "$NET_MODE" = "user" ]; then
  NETDEV="user,id=net0,hostfwd=tcp::${SSH_PORT}-:22"
else
  if [ "$(id -u)" -ne 0 ]; then
    echo "Bridged networking on macOS requires elevated privileges (vmnet-bridged)." >&2
    echo "Run with sudo, or use NET_MODE=user for NAT (no LAN visibility)." >&2
    exit 1
  fi
  NETDEV="vmnet-bridged,id=net0,ifname=${NET_IF}"
fi

qemu-system-x86_64 \
  -machine pc \
  -cpu max \
  -m 2048 \
  -smp 2 \
  -nographic \
  -drive file="$DISK",if=virtio,format=qcow2 \
  -drive file="$SEED",if=virtio,media=cdrom,readonly=on \
  -netdev "$NETDEV" \
  -device virtio-net-pci,netdev=net0,mac=$VM_MAC \
  -boot order=c \
  -serial mon:stdio

# (Use vmnet-shared if bridged is not allowed.)