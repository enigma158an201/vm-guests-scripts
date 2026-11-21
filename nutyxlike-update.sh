#!/usr/bin/env bash

# script by enigma158an201, available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git
### this script is intended to be run on nutyx-like Linux distribution to update the system and clean up packages.###

set -euo pipefail # set -euxo pipefail 

sLaunchDir="$(readlink -f "$(dirname "$0")")"
sParentDir="$(dirname "${sLaunchDir}")"
source "${sLaunchDir}/include/check-user-privileges" || source "${sParentDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env" || 	source "${sParentDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update" || 		source "${sParentDir}/include/git-self-update"

updateCards() {
	#if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} 'cards sync && cards upgrade'"; else cards sync && cards upgrade; fi
	#suExecCommand "cards sync && cards upgrade"
	if command -v "${sSuPfx}" &>/dev/null; then { suExecCommand "cards sync" || suExecCommand "cards upgrade"; } && \
												{ suExecCommand "cards upgrade --proceed" || suExecCommand "cards upgrade"; }
	elif test ${UID} -eq 0; then 				{ cards sync || cards upgrade; } && { cards upgrade --proceed || cards upgrade;} 
	fi
}
#useless: clean_cards() {}

mainCardslikeUpdate() {
	if ! command -v cards &>/dev/null; then echo -e "\t--> cards not found, exit now !!!"; exit 1
	else 									echo -e "\t--> cards found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
	fi
	updateScriptsViaGit
	updateCards #&& sudo shutdown 0
	bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
	if [[ ${bVirtualized} -eq 0 ]]; then 	suExecCommand "shutdown 0"; fi #eval ${sSuPfx}
}

mainCardslikeUpdate
