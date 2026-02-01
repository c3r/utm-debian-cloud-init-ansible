#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/cloud-init"

for vm_dir in "$BUILD_DIR"/*; do
  [ -d "$vm_dir" ] || continue
  vm_file_name=$(basename "$vm_dir")
  if [[ -f "$vm_dir/user-data" && -f "$vm_dir/meta-data" ]]; then
    genisoimage \
	-output "$vm_dir/$vm_file_name.iso" \
      -volid cidata \
      -joliet -rock \
      "$vm_dir/user-data" "$vm_dir/meta-data"
  fi
done

