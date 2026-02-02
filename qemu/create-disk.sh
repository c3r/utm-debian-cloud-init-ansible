#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <base_image> <target_image>"
  exit 1
fi

BASE_IMAGE="$1"
TARGET="$2"

mkdir -p "$(dirname "$TARGET")"

# Print target and base image for debugging
echo "Creating disk image:"
echo "  Base image: $BASE_IMAGE"
echo "  Target image: $TARGET"  

qemu-img create -f qcow2 -b "$BASE_IMAGE" -F qcow2 "$TARGET"
