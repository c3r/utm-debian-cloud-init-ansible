# Debian cloud-init + Ansible for QEMU lab

This repository provisions multiple Debian VMs on macOS using QEMU with vmnet-bridged networking. The workflow is split into three layers:

1. Artifact scripts (`scripts/*.sh`) for host-side build artifacts.
2. Declarative Ansible for idempotent in-guest configuration.
3. `Makefile` targets to orchestrate the end-to-end flow.

### Requirements
- QEMU (`qemu-system-x86_64`, `qemu-img`)
- Ansible
- `xorriso` (for seed ISO creation)

### Project layout
- `group_vars/all.yml`: single source of truth for VM/network settings
- `scripts/`: artifact and lifecycle scripts (`build`, `run`, `stop`, `bootstrap`)
- `ansible/playbooks/apply.yml`: idempotent configuration convergence
- `ansible/roles/common/`: reusable guest configuration role
- `build/`: generated disks, cloud-init artifacts, logs, and runtime PID files

### Configuration
Edit [group_vars/all.yml](group_vars/all.yml) to set:
- `dev_ssh_key`
- VM IPs/MACs under `nodes`
- `bridge_interface` (e.g. en0) and network settings
- base image name and location (`base_image_name`, `base_image_path`)

Place the Debian cloud image at the path defined by `base_image_path` (default: `build/images/debian-12-genericcloud-amd64.qcow2`).

## Customization

Key variables in `group_vars/all.yml` can be customized for different hypervisors:

- `vm_launch_command`: Full hypervisor launch command (default: QEMU). Customize for KVM, Xen, Hyper-V, etc.
- `disk_create_command`: Disk creation tool (default: qemu-img). Swap for LVM, Ceph, etc.
- `ssh_port`: SSH port for VM access (default: 22)

## Workflow

Two approaches, depending on your needs:

### Quick validate (recommended first-run)
This runs VMs and immediately validates connectivity:
```bash
make validate    # Runs: build → bootstrap → run → test-connectivity
make apply  
```

### Step-by-step (debugging/iteration)
Each target is independent, so you can compose them as needed:
```bash
make check                 # Validate syntax only (fast CI/CD check)
make build                 # Generate disks and cloud-init artifacts  
make bootstrap             # Boot VMs sequentially, wait for cloud-init
make run                   # Start all 4 VMs in parallel
make test-connectivity     # Verify network connectivity
make apply                 # Deploy ansible config to all VMs
```

This follows the Unix philosophy: each target has a single responsibility. You can debug individual layers without retesting the entire stack.

## Setup
1. Allow passwordless QEMU execution (required for vmnet-bridged):
        - `sudo ./setup-sudo.sh`
2. Check syntax and dependencies:
        - `make check`
3. Then choose your workflow:
        - **Automated**: `make validate && make apply` (full pipeline)
        - **Step-by-step**: `make build && make bootstrap && make run && make test-connectivity && make apply`

## Cleanup

To gracefully stop VMs started by scripts:

```bash
make stop
```

To force-kill all running QEMU VMs:

```bash
make kill-vms
```

Or manually: `./scripts/kill-vms.sh`

