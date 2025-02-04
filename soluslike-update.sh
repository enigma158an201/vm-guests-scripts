#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update"

update_solus() {
	if command -v sudo &>/dev/null; then 	sudo eopkg update-repo && sudo eopkg upgrade
	elif test ${UID} -eq 0; then 			eopkg update-repo && eopkg upgrade
	fi
}
clean_solus() {
	if command -v sudo &>/dev/null; then 	sudo eopkg remove-orphans && sudo eopkg clean
	elif test ${UID} -eq 0; then 			eopkg remove-orphans && eopkg clean
	fi
}
main_soluslike_update() {
	if ! command -v eopkg &>/dev/null; then echo -e "\t>>> eopkg command not found, exit now !!!"
											exit 1
	else 									echo -e "\t>>> eopkg command found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
	fi
	updateScriptsViaGit
	update_solus && clean_solus #&& poweroff #&& sudo shutdown 0
	bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
	if [[ ${bVirtualized} -eq 0 ]]; then 	poweroff; fi
}

main_soluslike_update
