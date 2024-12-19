#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

update_apt() {
	if command -v sudo; then 		sudo apt-get update && sudo apt-get full-upgrade
	else 							apt-get update && apt-get full-upgrade
	fi
}
clean_apt() {
	if command -v sudo; then 		sudo apt-get autoremove --purge && sudo apt-get clean
	else 							apt-get autoremove --purge && apt-get clean
	fi
}
clean_dpkg() {
	#shellcheck disable=SC2046
	if command -v sudo; then 		sudo apt-get autoremove --purge $(dpkg -l | grep ^rc | awk '{print $2}')
	else 							apt-get autoremove --purge $(dpkg -l | grep ^rc | awk '{print $2}')
	fi
}
updateScriptsViaGit(){
	set +euo pipefail #in case find cannot access some files or folders
	sTargetScript="$(find ~ -type f -iname git-pull-refresh.sh 2>/dev/null)" # -exec {} \;
	set -euo pipefail
	if test -f "${sTargetScript}"; then 
		sGitFolder="$(dirname "${sTargetScript}")"
		cd "${sGitFolder}" || exit 1
		bash -x "${sTargetScript}"
	fi
}
main_deblike_update() {
	if ! command -v apt-get || ! command -v apt; then 
		echo -e "\t>>> apt not found, exit now !!!"
		exit 1
	else
		echo -e "\t>>> apt found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
	fi
	updateScriptsViaGit
	update_apt && clean_apt && clean_dpkg && shutdown 0
}

main_deblike_update
