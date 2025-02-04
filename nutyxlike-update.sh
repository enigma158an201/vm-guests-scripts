#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update"

update_cards() {
	if command -v sudo &>/dev/null; then 	sudo cards sync && sudo cards upgrade
	else 									cards sync && cards upgrade
	fi
}
#useless: clean_cards() {}

main_cardslike_update() {
	if ! command -v cards &>/dev/null; then
		echo -e "\t>>> cards not found, exit now !!!"
		exit 1
	else
		echo -e "\t>>> cards found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
	fi
	updateScriptsViaGit
	update_cards && sudo shutdown 0
}

main_cardslike_update
