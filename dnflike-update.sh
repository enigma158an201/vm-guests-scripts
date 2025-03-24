#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update"

update_dnf() {
	#shellcheck disable=SC2154
	if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} 'dnf update && dnf upgrade'"
	else 										dnf update && dnf upgrade
	fi
}
clean_dnf() {
	if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} 'dnf autoremove && dnf clean all'"
	else 										dnf autoremove && dnf clean all
	fi
}
main_rockylinux_update() {
	if ! command -v dnf &>/dev/null; then 		echo -e "\t>>> dnf not found, exit now !!!"
												exit 1
	else 										echo -e "\t>>> dnf found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
	fi
	updateScriptsViaGit
	update_dnf && clean_dnf #&& shutdown 0
	bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
	if [[ ${bVirtualized} -eq 0 ]]; then 		eval "${sSuPfx} shutdown 0"; fi
}

main_rockylinux_update
