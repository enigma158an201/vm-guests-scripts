#!/usr/bin/env bash

# script by enigma158an201 and https://www.tecmint.com/remove-unwanted-services-from-linux/
set -euo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sLaunchDir="$(readlink -f "$(dirname "$0")")"
sParentDir="$(dirname "${sLaunchDir}")"
source "${sLaunchDir}/include/check-virtual-env" || 	source "${sParentDir}/include/check-virtual-env"
source "${sLaunchDir}/include/check-user-privileges" || source "${sParentDir}/include/check-user-privileges"

main_disable_services() {
	if command -v systemctl &>/dev/null; then
		#suExecCommand "systemctl daemon-reload"
		echo -e "\t>>> disabling unnecessary systemctl services for a VM environment, if applicable "
		echo -e "\t>>> Note: The services listed here are examples and may vary based on the specific VM environment and requirements."
		echo -e "\t>>> You may need to adjust the list of services based on your specific use case."
		
		# Disable services # qemu-guest-agent
		for sService in avahi-daemon bluetooth iscsi iscsid.socket iscsiuio.socket lvm2-monitor lvm2-lvmpolld.socket mdmonitor raid-check.timer \
						nfs-convert nfs-client.target cups postfix sssd hyperv-daemons apport zeitgeist telepathy; do
			suExecCommand "systemctl disable ${sService}.service || true"
		done
	fi
}
main_disable_services
