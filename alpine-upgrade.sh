#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update"

update_apk() {
	#shellcheck disable=SC2154
	if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} 'apk update && apk upgrade'"
	else 										apk update && apk upgrade
	fi
}
clean_apk() {
	if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} apk -v cache clean"
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
	if [[ ${bVirtualized} -eq 0 ]]; then 		eval "${sSuPfx} poweroff"; fi
}

main_alpine_update
