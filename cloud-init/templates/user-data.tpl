#cloud-config
hostname: {{ hostname }}

users:
  - name: dev
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - "{{ ssh_key }}"

network:
  version: 2
  ethernets:
    ens3:
      dhcp4: false
      addresses:
        - {{ ip }}/24
      gateway4: 192.168.64.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
