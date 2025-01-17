#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update"

update_apk() {
	if command -v sudo &>/dev/null; then 	sudo apk update && sudo apk upgrade
	else 									apk update && apk upgrade
	fi
}
clean_apk() {
	if command -v sudo &>/dev/null; then 	sudo apk -v cache clean
	else 									apk -v cache clean
	fi
}
main_alpine_update() {
	if ! command -v apk &>/dev/null; then 
		echo -e "\t>>> apk not found, exit now !!!"
		exit 1
	else
		echo -e "\t>>> apk found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
	fi
	updateScriptsViaGit
	update_apk && clean_apk && poweroff
}

main_alpine_update
