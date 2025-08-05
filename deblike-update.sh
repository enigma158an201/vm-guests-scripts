#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update"

update_apt() {
	#shellcheck disable=SC2154
	#if command -v "${sSuPfx}" &>/dev/null; then 	eval "${sSuPfx} 'apt-get update && apt-get full-upgrade'"
	#else 											apt-get update && apt-get full-upgrade; fi
	suExecCommand "apt-get update && apt-get full-upgrade" || return 1
}
clean_apt() {
	#shellcheck disable=SC2154
	#if command -v "${sSuPfx}" &>/dev/null; then 	eval "${sSuPfx} 'apt-get autoremove --purge && apt-get clean'"
	#else 											apt-get autoremove --purge && apt-get clean; fi
	suExecCommand "apt-get autoremove --purge && apt-get clean" || return 1
}
clean_dpkg() {
	#shellcheck disable=SC2046
	#if command -v "${sSuPfx}" &>/dev/null; then 	eval "${sSuPfx} 'apt-get autoremove --purge $(dpkg -l | grep ^rc | awk '{print $2}')'"	#removed ""
	#else 											apt-get autoremove --purge $(dpkg -l | grep ^rc | awk '{print $2}'); fi			#removed ""
	suExecCommand "apt-get autoremove --purge $(dpkg -l | grep ^rc | awk '{print $2}')" || return 1
}
upgrade_omv() {	if command -v omv-upgrade &>/dev/null; then 	suExecCommand omv-upgrade; fi }
upgrade_pve() {	if command -v pveupgrade &>/dev/null; then 		suExecCommand pveupgrade; fi }

main_deblike_update() {
	if [[ "$(checkRootPermissions)" = "true" ]]; then
		if command -v omv-upgrade &>/dev/null; then 	upgrade_omv; fi
		if command -v pveupgrade &>/dev/null; then 		upgrade_pve; fi
		if ! command -v apt-get &>/dev/null || ! command -v apt &>/dev/null; then 
			echo -e "\t>>> apt not found, exit now !!!"
			exit 1
		else
			echo -e "\t>>> apt found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
		fi
		updateScriptsViaGit
		update_apt && clean_apt && clean_dpkg
		bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
		if [[ ${bVirtualized} -eq 0 ]]; then 		suExecCommand "shutdown 0"; fi
	fi
}
main_deblike_update
