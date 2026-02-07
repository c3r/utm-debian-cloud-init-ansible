# Debian cloud-init + Ansible for QEMU lab

This repository provisions multiple Debian VMs with cloud-init and Ansible on macOS using QEMU with vmnet-bridged networking. It renders cloud-init configs, generates seed ISOs, creates per-VM disks, and runs QEMU with repeatable automation.

### Requirements
- QEMU (`qemu-system-x86_64`, `qemu-img`)
- Ansible
- `xorriso` (for seed ISO creation)

### Project layout
- `group_vars/all.yml`: Single source of truth for all VM settings
- `build/`: Generated disks and cloud-init artifacts

### Configuration
Edit [group_vars/all.yml](group_vars/all.yml) to set:
- `dev_ssh_key`
- VM IPs/MACs under `nodes`
- `bridge_interface` (e.g. en0) and network settings
- base image name and location (`base_image_name`, `base_image_path`)

Place the Debian cloud image at the path defined by `base_image_path` (default: `build/images/debian-12-genericcloud-amd64.qcow2`).

### Setup
1. Allow passwordless QEMU execution (required for vmnet-bridged):
        - `sudo ./setup-sudo.sh`
2. Generate artifacts and disks:
        - `make generate-cloud-init`
3. Bootstrap VMs sequentially (cloud-init + SSH checks):
        - `make setup`
4. Run all VMs in parallel:
        - `make run`
 

