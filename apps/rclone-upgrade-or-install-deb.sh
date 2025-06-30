#!/usr/bin/env bash

#RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NOCOLOR='\033[0m' # No Color

set -euo pipefail

preChecks() {
	source /etc/os-release
	if [[ ! ${ID_LIKE:-} =~ debian ]] && [[ ${ID} = debian ]]; then echo -e "\t${RED}>>> Please run only on debian like${NOCOLOR}";	return 1; fi
	if ! command -v dpkg &>/dev/null; then 							return 1; fi
	mkdir -p "${sWorkDir}" || return 1
	return 0 #|| exit 1
}
getLatestDeb() {
	cd "${sWorkDir}" || { echo -e "\t${RED}>>> ${sWorkDir} is not writable${NOCOLOR}" && exit 1; }
	LANG=C wget -N "${sDebUrl}" 2>&1 && return 0
}
setupLatestApt() {
	if ! { apt list --installed 2>&1 | grep rclone-browser &>/dev/null; }; then
		if [[ ${EUID} -eq 0 ]]; then 			apt-get install rclone-browser rclone
		elif command -v sudo &>/dev/null; then 	sudo apt-get install rclone-browser rclone
		fi
	fi
}
setupLatestDeb() {
	if [[ -f "${sDebPath}" ]]; then
		if [[ ${EUID} -eq 0 ]]; then 			dpkg -i "${sDebPath}" && return 0 || return 1
		elif command -v sudo &>/dev/null; then 	sudo dpkg -i "${sDebPath}" && return 0 || return 1
		else echo -e "\t${RED} Please run with sufficient privileges!${NOCOLOR}";return 1
		fi
	else 	return 1
	fi
}
checkAlreadyInstalled() {
	sVersionInstalled=$(dpkg -s rclone | grep -i version)
	sVersionInstalled=${sVersionInstalled##* }
	sVersionDownloaded=$(dpkg-deb -f "${sDebPath}" Version)
	if [[ ${sVersionInstalled} = "${sVersionDownloaded}" ]]; then echo "true"
	else echo "false"
	fi
}

mainUpgradeDpkg() {
	sWorkDir=${HOME}/.deb-pkgs #/tmp
	if ! preChecks; then exit 1; fi
	setupLatestApt || exit 1
	sDebUrl=https://downloads.rclone.org/rclone-current-linux-amd64.deb
	sDebPath="${sWorkDir}/$(basename "${sDebUrl}")"
	sDebDlOut=$(getLatestDeb)
	bInstalled=$(checkAlreadyInstalled)
	if [[ ${sDebDlOut} =~ "Omitting download" ]]; then echo -e "\t${YELLOW}>>> deb file '${sDebUrl}' already downloaded${NOCOLOR}"; fi
	if [[ ${bInstalled} = "false" ]]; then 	setupLatestDeb
	else echo -e "\t${GREEN}>>> deb file '${sDebUrl}' already installed${NOCOLOR}"
	fi
}
mainUpgradeDpkg
