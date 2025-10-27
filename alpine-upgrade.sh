#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sLaunchDir="$(readlink -f "$(dirname "$0")")"
sParentDir="$(dirname "${sLaunchDir}")"
source "${sLaunchDir}/include/check-user-privileges" || source "${sParentDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env" || 	source "${sParentDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update" || 		source "${sParentDir}/include/git-self-update"

update_apk() {
	#shellcheck disable=SC2154
	if command -v "${sSuPfx}" &>/dev/null; then suExecCommand 'apk update && apk upgrade' #eval "${sSuPfx}"
	else 										apk update && apk upgrade
	fi
}
clean_apk() {
	if command -v "${sSuPfx}" &>/dev/null; then suExecCommand "apk -v cache clean" #eval ${sSuPfx} 
	else 										apk -v cache clean
	fi
}
main_alpine_update() {
	if ! command -v apk &>/dev/null; then 		echo -e "\t>>> apk not found, exit now !!!"
												exit 1
	else 										echo -e "\t>>> apk found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
	fi
	updateScriptsViaGit
	update_apk && clean_apk #&& poweroff #&& sudo shutdown 0
	bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
	if [[ ${bVirtualized} -eq 0 ]]; then 		suExecCommand "poweroff"; fi #eval ${sSuPfx} 
}

main_alpine_update
