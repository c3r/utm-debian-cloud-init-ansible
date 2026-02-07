.PHONY: help validate-cloud-init generate-cloud-init create-disks run setup clean

help:
	@echo "Targets:"
	@echo "  make validate-cloud-init - validate vars and templates"
	@echo "  make generate-cloud-init - generate cloud-init + disks"
	@echo "  make setup              - run setup sequentially"
	@echo "  make run                - run all VMs in parallel"
	@echo "  make clean             - remove build artifacts"

validate-cloud-init:
	ansible-playbook generate-cloud-init.yml --check

create-disks:
	ansible-playbook create-disks.yml

generate-cloud-init: validate-cloud-init create-disks
	ansible-playbook generate-cloud-init.yml

setup: generate-cloud-init
	ansible-playbook setup.yml

run: setup
	ansible-playbook run.yml

clean:
	rm -rf build/
