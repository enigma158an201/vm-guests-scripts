#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sLaunchDir="$(readlink -f "$(dirname "$0")")"
sParentDir="$(dirname "${sLaunchDir}")"
source "${sLaunchDir}/include/check-user-privileges" || source "${sParentDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env" || 	source "${sParentDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update" || 		source "${sParentDir}/include/git-self-update"

updatehDnf() {
	#shellcheck disable=SC2154
	if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} 'dnf update'" && eval "${sSuPfx} 'dnf upgrade'"
	else 										dnf update && dnf upgrade
	fi
}
cleanDnf() {
	if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} 'dnf autoremove'" && eval "${sSuPfx} 'dnf clean all'"
	else 										dnf autoremove && dnf clean all
	fi
}
mainRockylinuxUpdate() {
	if ! command -v dnf &>/dev/null; then 		echo -e "\t--> dnf not found, exit now !!!"
												exit 1
	else 										echo -e "\t--> dnf found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
	fi
	updateScriptsViaGit
	updateDnf && cleanDnf #&& shutdown 0
	bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
	if [[ ${bVirtualized} -eq 0 ]]; then 		eval "${sSuPfx} shutdown 0"; fi
}

mainRockylinuxUpdate
