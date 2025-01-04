#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

checkRootPermissions() {
	if [[ ${UID} = 0 ]] || [[ ${UID} = 0 ]]; then echo "true"; else echo "false"; fi
}
checkVirtEnv() {
	bFoundString=1 #false
	if command -v sudo &>/dev/null; then 			sResult="$(sudo dmesg --notime)"
	else 											sResult="$(dmesg --notime)"; fi
	for sVirtEnv in virtualbox vboxservice vmware; do
		if [[ ${sResult,,} =~ ${sVirtEnv} ]]; then 	bFoundString=0 #${bFoundString} || echo "true")" #="$(echo  | grep -i )"
		#else 										bFoundString="$(${bFoundString} || echo "false")"
		fi
	done
	echo "${bFoundString}"
}
update_apt() {
	if command -v sudo &>/dev/null; then 			sudo apt-get update && sudo apt-get full-upgrade
	else 											apt-get update && apt-get full-upgrade
	fi
}
clean_apt() {
	if command -v sudo &>/dev/null; then 			sudo apt-get autoremove --purge && sudo apt-get clean
	else 											apt-get autoremove --purge && apt-get clean
	fi
}
clean_dpkg() {
	#shellcheck disable=SC2046
	if command -v sudo &>/dev/null; then 			sudo apt-get autoremove --purge $(dpkg -l | grep ^rc | awk '{print $2}')	#removed ""
	else 											apt-get autoremove --purge $(dpkg -l | grep ^rc | awk '{print $2}')			#removed ""
	fi
}
updateScriptsViaGit(){
	set +euo pipefail #in case find cannot access some files or folders
	sTargetScript="$(find ~ -nowarn -type f -iname git-pull-refresh.sh 2>/dev/null)" # -exec {} \;
	set -euo pipefail
	if test -f "${sTargetScript}"; then 			sGitFolder="$(dirname "${sTargetScript}")"
													cd "${sGitFolder}" || exit 1
													bash -x "${sTargetScript}"
	fi
}
main_deblike_update() {
	if [[ "$(checkRootPermissions)" = "true" ]]; then
		if ! command -v apt-get &>/dev/null || ! command -v apt &>/dev/null; then 
			echo -e "\t>>> apt not found, exit now !!!"
			exit 1
		else
			echo -e "\t>>> apt found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
		fi
		updateScriptsViaGit
		update_apt && clean_apt && clean_dpkg
		bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
		if [[ ${bVirtualized} -eq 0 ]]; then shutdown 0; fi
	fi
}

main_deblike_update
