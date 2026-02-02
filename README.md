# Debian cloud-init + ansible for UTM lab

This repository automates provisioning multiple Debian virtual machines with UTM, using cloud-init for first-boot configuration and Ansible for post-provisioning tasks. It creates cloud-init config files, generates seed ISOs, and provides a complete workflow to deploy and manage VMs with reproducible infrastructure automation.


This approach mirrors real-world cloud workflows, bringing cloud-style automation to local UTM development setups.

### Templates and variables
- `cloud-init/templates/user-data.tpl` and `cloud-init/templates/user-data.tpl`: Base cloud-init templates
- `cloud-init/vars.yml`: Variables defining VM names, static IPs, SSH public keys, etc.

These are combined to produce per-VM `user-data` and `meta-data` files.

### Step-by-step guide

Install required tools on macOS:
- UTM
- Ansible
- `genisoimage` (or `cloud-image-utils`)

Steps:
1. create a Debian VM template in UTM and make sure `cloud-init` is installed and enabled
3. shut down the template VM and clone it once per VM
4. for each VM:
        a. attach its corresponding seed ISO as a CD/DVD
        b. ensure network is *Shared Network*
        c. boot the VM **once**
        d. `ssh` into it by `ssh dev@<VM_IP>` and validate hostname, IP, DHCP config, etc.
5. ensure `ansible/inventory/hosts.ini` lists the VM IPs and run `ansible-playbook ansible/playbooks/setup.yml`
 

