#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update"

get_freebsd_latest_version() {
	curl -s https://download.freebsd.org/releases/amd64/ | awk '{print $3}' | grep RELEASE | tr -d '"' | tr -d '/' | cut -f2 -d'=' | sort | tail -1
}
get_freebsd_installed_release() {
	sRelease=$(freebsd-version)
	echo "${sRelease#*-p}"
}

update_freebsd() {
	if ! command -v freebsd-update &>/dev/null; then
		#shellcheck disable=SC2154
		if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} 'freebsd-update fetch && freebsd-update install'"
		elif test ${UID} -eq 0; then 				freebsd-update fetch && freebsd-update install
		fi
	fi 
}
upgrade_release_freebsd() {
	sFreebsdLatest="$(get_freebsd_latest_version)"
	sFreebsdCurrent="$(get_freebsd_installed_release)" #"$(freebsd-version | cut -d '-' -f 1)"
	if [[ ${sFreebsdLatest} -ne ${sFreebsdCurrent} ]]; then
		echo -e "\t>>> FreeBSD ${sFreebsdCurrent} is not the latest version, upgrading to ${sFreebsdLatest}"
		if ! command -v freebsd-update &>/dev/null; then
			#shellcheck disable=SC2154
			if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} 'freebsd-update upgrade -r ${sFreebsdLatest}'"
			elif test ${UID} -eq 0; then 				freebsd-update upgrade -r "${sFreebsdLatest}"
			fi
		fi
		update_freebsd
	else
		echo -e "\t>>> FreeBSD ${sFreebsdCurrent} is the latest version, no need to upgrade"
		exit 0
	fi
	
}
update_bsd() {
	if command -v "${sSuPfx}" &>/dev/null; then 	eval "${sSuPfx} 'pkg update -f && pkg upgrade'"
	elif test ${UID} -eq 0; then 					pkg update -f && pkg upgrade
	fi
}
clean_bsd() {
	if command -v "${sSuPfx}" &>/dev/null; then 	eval "${sSuPfx} 'pkg autoremove && pkg clean'"
	elif test ${UID} -eq 0; then 					pkg autoremove && pkg clean
	fi
}
main_bsdlike_update() {
	if ! command -v pkg &>/dev/null; then 			echo -e "\t>>> pkg command not found, exit now !!!"
													exit 1
	else 											echo -e "\t>>> pkg command found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
	fi
	updateScriptsViaGit
	update_freebsd
	update_bsd && upgrade_release_freebsd && clean_bsd #&& poweroff #&& sudo shutdown 0
	#bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
	#if [[ ${bVirtualized} -eq 0 ]]; then 			eval "${sSuPfx} poweroff"; fi
}

main_bsdlike_update
