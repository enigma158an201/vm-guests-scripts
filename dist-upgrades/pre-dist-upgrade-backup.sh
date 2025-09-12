#!/usr/bin/env bash

# script by enigma158an201 12/09/2025 @ 23:08
set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

#https://www.debian.org/releases/trixie/release-notes/upgrading.fr.html

sLaunchDir="$(readlink -f "$(dirname "$0")")"
#if [[ "${sLaunchDir}" = "." ]] || [[ "${sLaunchDir}" = "include" ]] || [[ "${sLaunchDir}" = "" ]]; then eval sLaunchDir="$(pwd)"; fi
#sLaunchDir="${sLaunchDir//include/}"
source "${sLaunchDir}/../include/check-user-privileges" # ./include/test-superuser-privileges.sh moved to ${sLaunchDir}/../include/test-superuser-privileges

sDistBackupFolder="/dist-backup"

sEtcFolder=/etc
sVarLibDpkg=/var/lib/dpkg
sVarLibAptExt=/var/lib/apt/extended_states
sDpkgGetSelections="${sDistBackupFolder}/dpkg-get-selections" # dpkg --get-selections '*' # (the quotes are important)
sVarLibAptitudePkgstates="/var/lib/aptitude/pkgstates"

getDebianVersion() { 			if [[ -f /etc/debian_version ]]; then 			sDebMainVersion="$(cat /etc/debian_version)"; echo "${sDebMainVersion%%.*}"
								else 											echo "false"; exit 1; fi; }
getDiskBackupFolder() { 		if [[ ! -d ${sDistBackupFolder} ]]; then 		mkdir -p "${sDistBackupFolder}"; chmod 700 "${sDistBackupFolder}"; fi; }
backupDpkgSelections() { 		if command -v dpkg &>/dev/null; then 			dpkg --get-selections '*' > "${sDpkgGetSelections}"; fi; }
backupAptitudePkgstates() { 	if [[ -f ${sVarLibAptitudePkgstates} ]]; then 	cp -a "${sVarLibAptitudePkgstates}" "${sDistBackupFolder}/"; fi; }
backupAptExtendedStates() { 	if [[ -f ${sVarLibAptExt} ]]; then 				cp -a "${sVarLibAptExt}" "${sDistBackupFolder}/"; fi; }
backupEtcFolder() { 			if [[ -d ${sEtcFolder} ]]; then 				tar -czf "${sDistBackupFolder}/etc-backup.tar.gz" -C / etc; fi; }
backupVarLibDpkg() { 			if [[ -d ${sVarLibDpkg} ]]; then 				tar -czf "${sDistBackupFolder}/var-lib-dpkg-backup.tar.gz" -C / var/lib/dpkg; fi; }	

main() {
	getDiskBackupFolder
	backupDpkgSelections
	backupAptitudePkgstates
	backupAptExtendedStates
	backupEtcFolder
	backupVarLibDpkg
	echo "Backup completed and saved to ${sDistBackupFolder}"
	echo "You can now proceed with the distribution upgrade."
}
main
