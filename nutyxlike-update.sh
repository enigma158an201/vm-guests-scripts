#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

update_cards() {
	if command -v sudo &>/dev/null; then 	sudo cards sync && sudo cards upgrade
	else 									cards sync && cards upgrade
	fi
}
#useless: clean_cards() {}
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

main_cardslike_update() {
	if ! command -v cards &>/dev/null; then
		echo -e "\t>>> cards not found, exit now !!!"
		exit 1
	else
		echo -e "\t>>> cards found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
	fi
	updateScriptsViaGit
	update_cards && sudo shutdown 0
}

main_cardslike_update
