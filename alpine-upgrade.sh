#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

update_apk() {
	if command -v sudo; then 		sudo apk update && sudo apk upgrade
	else 							apk update && apk upgrade
	fi
}
clean_apk() {
	if command -v sudo; then 		sudo apk -v cache clean
	else 							apk -v cache clean
	fi
}
updateScriptsViaGit(){
	set +euo pipefail #in case find cannot access some files or folders
	sTargetScript="$(find ~ -nowarn -type f -iname git-pull-refresh.sh 2>/dev/null)" # -exec {} \;
	set -euo pipefail
	if test -f "${sTargetScript}"; then 
		sGitFolder="$(dirname "${sTargetScript}")"
		cd "${sGitFolder}" || exit 1
		bash -x "${sTargetScript}"
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
