#!/usr/bin/env bash

# script by enigma158an201, available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git
### this script is intended to be run on any Linux distribution to check for git updates and pull them if needed.###

set -euo pipefail # set -euxo pipefail

findScriptsGitFolder() { set +euo pipefail; find ~ -nowarn -type d -iname 'vm-guests-script*' 2>/dev/null; set +euo pipefail; }
checkGitUpdates() { git pull --dry-run | grep -q -v -E 'Already up-to-date.|Déjà à jour.' && return 0; } #|| return 1 #changed=1
pullGitUpdates() { if git pull; then echo -e "\t--> git pulled successfully"; else echo -e "\t--> git pull failed, exit now !!!"; exit 1; fi; }

mainGitProcess() {
	if ! command -v git &>/dev/null; then echo -e "\t--> git not found, exit now !!!"; exit 1
	else echo -e "\t--> git found, this script will: check and fetch git updates if needed"
	fi
	sGitFolder=$(findScriptsGitFolder)
	cd "${sGitFolder}" || exit 1
	checkGitUpdates || pullGitUpdates
}
mainGitProcess
