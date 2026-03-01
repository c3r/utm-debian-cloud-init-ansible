#!/bin/bash
set -euo pipefail

echo "Killing all running QEMU VMs..."
sudo pkill -9 -f qemu-system-x86_64 || echo "No QEMU processes found or already killed"
echo "Done"
