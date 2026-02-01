# Debian cloud-init + ansible for UTM lab

This repository automates provisioning multiple Debian virtual machines with UTM, using cloud-init for first-boot configuration and Ansible for post-provisioning tasks. It creates cloud-init config files, generates seed ISOs, and provides a complete workflow to deploy and manage VMs with reproducible infrastructure automation.


This approach mirrors real-world cloud workflows, bringing cloud-style automation to local UTM development setups.

### Templates and variables
`cloud-init/templates/user-data.tpl`: Base cloud-init template
`cloud-init/vars.yml`: Variables defining VM names, static IPs, SSH public keys, etc.


These are combined to produce per-VM user-data and meta-data files.





