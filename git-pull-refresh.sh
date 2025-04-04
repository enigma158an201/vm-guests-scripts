#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

findScriptsGitFolder() {
	set +euo pipefail
	find ~ -nowarn -type d -iname 'vm-guests-script*' 2>/dev/null
	set +euo pipefail
}

checkGitUpdates() {
	git pull --dry-run | grep -q -v -E 'Already up-to-date.|Déjà à jour.' && return 0 #|| return 1 #changed=1
}

pullGitUpdates() {
	git pull
}

main_git_process() {
	if ! command -v git &>/dev/null; then
		echo -e "\t>>> git not found, exit now !!!"
		exit 1
	else
		echo -e "\t>>> git found, this script will: check and fetch git updates if needed"
	fi
	sGitFolder=$(findScriptsGitFolder)
	cd "${sGitFolder}"
	checkGitUpdates || pullGitUpdates
}

main_git_process
