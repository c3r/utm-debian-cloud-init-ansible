.PHONY: help validate-cloud-init generate-cloud-init create-disks run setup clean

help:
	@echo "Targets:"
	@echo "  make validate-cloud-init - validate vars and templates"
	@echo "  make generate-cloud-init - generate cloud-init + disks"
	@echo "  make setup              - run setup sequentially"
	@echo "  make run                - run all VMs in parallel"
	@echo "  make clean             - remove build artifacts"

validate-cloud-init:
	ansible-playbook scripts/generate-cloud-init.yml --check || { echo "Validation failed."; exit 1; }

create-disks:
	ansible-playbook scripts/create-disks.yml || { echo "Disk creation failed."; exit 1; }

generate-cloud-init: validate-cloud-init create-disks
	ansible-playbook scripts/generate-cloud-init.yml || { echo "Create failed."; exit 1; }

setup: generate-cloud-init
	ansible-playbook scripts/setup.yml || { echo "Setup failed."; exit 1; }

run: setup
	ansible-playbook scripts/run.yml || { echo "Run failed."; exit 1; }

clean:
	rm -rf build/ || { echo "Clean failed."; exit 1; }
