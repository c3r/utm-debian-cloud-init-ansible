#!/usr/bin/env bash
set -euo pipefail

BASE_IMAGE="$1"
TARGET_DIR="$2"

if [ -z "$BASE_IMAGE" ] || [ -z "$TARGET_DIR" ]; then
  echo "Usage: $0 <base_image> <target_directory>"
  exit 1
fi

mkdir -p "$TARGET_DIR"

for disk in jumpbox node0 node1 server; do
  TARGET="$TARGET_DIR/$disk.qcow2"
  echo "Creating disk: $TARGET"
  ./qemu/create-disk.sh "$BASE_IMAGE" "$TARGET" || {
    echo "Failed to create disk $disk.";
    exit 1;
  }
done