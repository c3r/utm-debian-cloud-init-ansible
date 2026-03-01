#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib.sh"

require_cmd yq
require_cmd xorriso

load_scalar_vars

# Loop through each VM defined in the configuration and generate cloud-init artifacts for it. For each VM, we create a directory for its cloud-init files, generate the user-data, meta-data, and network-config files using envsubst to substitute environment variables, and then create an ISO image containing these files using xorriso. The resulting ISO will be used as a seed image when booting the VM to provide it with the necessary configuration for cloud-init.
while IFS='|' read -r vm_name vm_ip vm_mac; do
  vm_dir="${REPO_ROOT}/${CLOUD_INIT_DIR}/${vm_name}"
  mkdir -p "${vm_dir}"

  # Export per-VM variables for envsubst substitution
  export vm_name vm_ip vm_mac

# Generate the cloud-init configuration files (user-data, meta-data, network-config) for this VM using envsubst to substitute environment variables in the templates. The generated files are saved in the VM's cloud-init directory. We use separate templates for user-data, meta-data, and network-config, which allow us to customize the configuration for each VM based on its name, IP address, and MAC address.
  envsubst < "${SCRIPT_DIR}/templates/user-data" > "${vm_dir}/user-data"
  envsubst < "${SCRIPT_DIR}/templates/meta-data" > "${vm_dir}/meta-data"
  envsubst < "${SCRIPT_DIR}/templates/network-config" > "${vm_dir}/network-config"

# Create an ISO image containing the cloud-init configuration files using xorriso. The -volid option sets the volume ID to "cidata", which is recognized by cloud-init as a valid seed image. The generated ISO is saved in the VM's cloud-init directory and will be used as a seed image when booting the VM to provide it with the necessary configuration for cloud-init. We include the user-data, meta-data, and network-config files in the ISO so that cloud-init can read them during the boot process and configure the VM accordingly.
  xorriso -as mkisofs \
    -volid cidata \
    -joliet \
    -rock \
    -input-charset utf-8 \
    -output "${vm_dir}/${vm_name}.iso" \
    "${vm_dir}/user-data" \
    "${vm_dir}/meta-data" \
    "${vm_dir}/network-config"

  echo "Generated cloud-init artifacts for ${vm_name}"
done < <(node_rows)
