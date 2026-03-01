.PHONY: help validate build generate-cloud-init create-disks bootstrap apply setup run stop kill-vms clean

ANSIBLE_CONFIG := ansible/ansible.cfg
ANSIBLE_VARS := -e @group_vars/all.yml
SHELL := bash
.SHELLFLAGS := -euo pipefail -c

define require_cmd
	@command -v $(1) >/dev/null 2>&1 || (echo "Error: $(1) is required but not installed" >&2 && exit 1)
endef

help:
	@echo "Targets:"
	@echo "  make validate           - validate scripts and ansible syntax"
	@echo "  make generate-cloud-init- generate cloud-init artifacts"
	@echo "  make create-disks       - create per-VM disks"
	@echo "  make build              - generate artifacts + disks"
	@echo "  make bootstrap          - boot VMs one-by-one to finish cloud-init"
	@echo "  make apply              - apply idempotent guest config via ansible"
	@echo "  make setup              - build + bootstrap"
	@echo "  make run                - run all VMs in parallel"
	@echo "  make stop               - stop VMs started by scripts"
	@echo "  make kill-vms           - hard-kill all running QEMU VMs"
	@echo "  make clean              - remove build artifacts"

validate:
	$(call require_cmd,bash)
	$(call require_cmd,ansible-playbook)
	$(call require_cmd,yq)
	bash -n scripts/*.sh
	ANSIBLE_CONFIG=$(ANSIBLE_CONFIG) ansible-playbook -i localhost, ansible/playbooks/apply.yml --syntax-check $(ANSIBLE_VARS)

create-disks:
	$(call require_cmd,yq)
	$(call require_cmd,qemu-img)
	./scripts/create-disks.sh

generate-cloud-init:
	$(call require_cmd,yq)
	$(call require_cmd,xorriso)
	./scripts/generate-cloud-init.sh

build: generate-cloud-init create-disks

bootstrap: build
	$(call require_cmd,qemu-system-x86_64)
	$(call require_cmd,sudo)
	./scripts/bootstrap-vms.sh

# The apply target runs the Ansible playbook to apply idempotent guest configuration to the VMs. It uses the ANSIBLE_CONFIG variable to specify the Ansible configuration file and passes the variables from the group_vars/all.yml file. This allows you to run the playbook against the localhost inventory, which is useful for applying configuration to the VMs after they have been bootstrapped and are running. The playbook will connect to the VMs using SSH and apply the desired configuration as defined in the Ansible roles and tasks.
apply:
	$(call require_cmd,ansible-playbook)
	ANSIBLE_CONFIG=$(ANSIBLE_CONFIG) ansible-playbook -i localhost, ansible/playbooks/apply.yml $(ANSIBLE_VARS)

setup: bootstrap

run: build
	$(call require_cmd,qemu-system-x86_64)
	./scripts/run-vms.sh

stop:
	$(call require_cmd,yq)
	$(call require_cmd,sudo)
	./scripts/stop-vms.sh

kill-vms:
	$(call require_cmd,sudo)
	./scripts/kill-vms.sh

clean:
	rm -rf build/
