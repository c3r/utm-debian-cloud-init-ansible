#!/usr/bin/env bash
set -euo pipefail

# This script creates disk images for each VM defined in the configuration, using a base image as a template.
# It uses qemu-img to create new disk images in the specified format (defaulting to qcow2) that are based on the provided base image.
# If a disk image already exists for a VM, it will skip creating it to avoid overwriting any existing data.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib.sh"

require_cmd python3
require_cmd qemu-img
require_python_yaml

load_scalar_vars

# Ensure the disk directory exists
mkdir -p "${REPO_ROOT}/${DISK_DIR}"

# Loop through each VM defined in the configuration and create a disk image for it if it doesn't already exist
while IFS= read -r vm_name; do
  target_image="${REPO_ROOT}/${DISK_DIR}/${vm_name}.${DISK_FORMAT}"
  if [ -f "${target_image}" ]; then
    echo "Disk exists, skipping: ${target_image}"
    continue
  fi

# Create a new disk image based on the base image using qemu-img
# The -f option specifies the format of the new disk image (e.g., qcow2), and the -b option specifies the base image to use as a template.
  qemu-img create -f qcow2 -b "${BASE_IMAGE_PATH}" -F qcow2 "${target_image}"
  echo "Created disk: ${target_image}"
done < <(node_names)
