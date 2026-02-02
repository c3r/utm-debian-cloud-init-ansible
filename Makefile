.PHONY: help validate apply disks run clean

help:
	@echo "Targets:"
	@echo "  make validate  - validate vars and templates"
	@echo "  make apply     - generate cloud-init + disks"
	@echo "  make run       - run all VMs"
	@echo "  make clean     - remove build artifacts"

validate:
	ansible-playbook scripts/generate-cloud-init.yml --check || { echo "Validation failed."; exit 1; }

apply: validate disks
	ansible-playbook scripts/generate-cloud-init.yml || { echo "Apply failed."; exit 1; }

disks:
	./scripts/create-disks.sh $(shell pwd)/qemu/images/debian-12-genericcloud-arm64.qcow2 $(shell pwd)/build/disks

run:
	for disk in jumpbox node0 node1 server; do \
	  ./qemu/run.sh $$disk build/disks/$$disk.qcow2 build/cloud-init/$$disk/$$disk.iso || { echo "Failed to run VM $$disk."; exit 1; }; \
	done

clean:
	rm -rf build/ || { echo "Clean failed."; exit 1; }
