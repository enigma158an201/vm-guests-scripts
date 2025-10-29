#!/usr/bin/env bash

# script by enigma158an201 and https://www.tecmint.com/remove-unwanted-services-from-linux/
set -euo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sLaunchDir="$(readlink -f "$(dirname "$0")")"
sParentDir="$(dirname "${sLaunchDir}")"
source "${sLaunchDir}/include/check-virtual-env" || 	source "${sParentDir}/include/check-virtual-env"
source "${sLaunchDir}/include/check-user-privileges" || source "${sParentDir}/include/check-user-privileges"
source "${sLaunchDir}/include/colors" || 				source "${sParentDir}/include/colors"

main_disable_services() {
	if command -v systemctl &>/dev/null; then
		tDisableServices=( avahi-daemon bluetooth iscsi iscsid.socket iscsiuio.socket lvm2-monitor lvm2-lvmpolld.socket mdmonitor raid-check.timer \
							nfs-convert nfs-client.target cups postfix sssd hyperv-daemons apport zeitgeist telepathy saned )
		#suExecCommand "systemctl daemon-reload"
		echo -e "\t>>> disabling unnecessary systemctl services for a VM environment, if applicable "
		echo -e "\t>>> Note: The services listed here are examples and may vary based on the specific VM environment and requirements."
		echo -e "\t>>> You may need to adjust the list of services based on your specific use case."
		
		# Disable services # qemu-guest-agent
		for sService in "${tDisableServices[@]}"; do
			if [[ ! ${sService} =~ .socket ]] && [[ ! ${sService} =~ .target ]] && [[ ! ${sService} =~ .timer ]] && [[ ! ${sService} =~ .slice ]]; then 
				sService="${sService}.service"
			fi
			if systemctl is-enabled "${sService}" &>/dev/null || systemctl is-active "${sService}" &>/dev/null; then
				echo -e "\t>>> disabling service: ${sService}"
				suExecCommand "systemctl disable ${sService} || true"
			else
				echo -e "\t>>> service: ${sService} is not enabled, skipping disable command"
			fi
		done
	fi
	unset sService
}
main_disable_services
