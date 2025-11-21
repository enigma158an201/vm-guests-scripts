#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sLaunchDir="$(readlink -f "$(dirname "$0")")"
sParentDir="$(dirname "${sLaunchDir}")"
source "${sLaunchDir}/include/check-user-privileges" || source "${sParentDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env" || 	source "${sParentDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update" || 		source "${sParentDir}/include/git-self-update"

update_void() {
	#shellcheck disable=SC2154
	eval "${sSuPfx} xbps-install -Su"
}
clean_void() {
	eval "${sSuPfx} xbps-remove -yO"
	#shellcheck disable=SC2046
	if [[ ! $(vkpurge list | head -n -1) = '' ]]; then eval "${sSuPfx} vkpurge rm $(vkpurge list | head -n -1)"; fi #all
}
main_void_update() {
	if [[ "$(checkRootPermissions)" = "true" ]]; then
		if ! command -v xbps-install || ! command -v xbps-remove; then 
			echo -e "\t--> xbps not found, exit now !!!"
			exit 1
		else
			echo -e "\t--> xbps found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
		fi
		updateScriptsViaGit
		update_void && clean_void #&& poweroff # && shutdown 0
		bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
		if [[ ${bVirtualized} -eq 0 ]]; then poweroff; fi
	fi
}

main_void_update
