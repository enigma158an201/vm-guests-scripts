#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sLaunchDir="$(readlink -f "$(dirname "$0")")"
sParentDir="$(dirname "${sLaunchDir}")"
source "${sLaunchDir}/include/check-user-privileges" || source "${sParentDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env" || 	source "${sParentDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update" || 		source "${sParentDir}/include/git-self-update"

updateApt() {
	#shellcheck disable=SC2154
	#if command -v "${sSuPfx}" &>/dev/null; then 	eval "${sSuPfx} 'apt-get update && apt-get full-upgrade'"
	#else 											apt-get update && apt-get full-upgrade; fi
	{ suExecCommand "apt-get update" && suExecCommand "apt-get full-upgrade"; } || return 1
}
cleanApt() {
	#shellcheck disable=SC2154
	#if command -v "${sSuPfx}" &>/dev/null; then 	eval "${sSuPfx} 'apt-get autoremove --purge && apt-get clean'"
	#else 											apt-get autoremove --purge && apt-get clean; fi
	{ suExecCommand "apt-get autoremove --purge" && suExecCommand "apt-get clean"; } || return 1
}
cleanDpkg() {
	#shellcheck disable=SC2046
	#if command -v "${sSuPfx}" &>/dev/null; then 	eval "${sSuPfx} 'apt-get autoremove --purge $(dpkg -l | grep ^rc | awk '{print $2}')'"	#removed ""
	#else 											apt-get autoremove --purge $(dpkg -l | grep ^rc | awk '{print $2}'); fi			#removed ""
	suExecCommand "apt-get autoremove --purge $(dpkg -l | grep ^rc | awk '{print $2}')" || return 1
}
upgradeOmv() {	if command -v omv-upgrade &>/dev/null; then 	suExecCommand omv-upgrade; fi }
upgradePve() {	if command -v pveupgrade &>/dev/null; then 		suExecCommand pveupgrade; fi }

mainDeblikeUpdate() {
	if [[ "$(checkRootPermissions)" = "true" ]]; then
		if command -v omv-upgrade &>/dev/null; then 	upgradeOmv; fi
		if command -v pveupgrade &>/dev/null; then 		upgradePve; fi
		if ! command -v apt-get &>/dev/null || ! command -v apt &>/dev/null; then echo -e "\t--> apt not found, exit now !!!"; 	exit 1
		else echo -e "\t--> apt found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
		fi
		updateScriptsViaGit
		updateApt && cleanApt && cleanDpkg
		bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
		if [[ ${bVirtualized} -eq 0 ]]; then 		suExecCommand "shutdown 0"; fi
	fi
}
mainDeblikeUpdate
