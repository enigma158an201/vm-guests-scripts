#!/usr/bin/env bash

# script by enigma158an201 12/09/2025 @ 23:08
set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

#https://www.debian.org/releases/trixie/release-notes/upgrading.fr.html

sLaunchDir="$(readlink -f "$(dirname "$0")")"
#if [[ "${sLaunchDir}" = "." ]] || [[ "${sLaunchDir}" = "include" ]] || [[ "${sLaunchDir}" = "" ]]; then eval sLaunchDir="$(pwd)"; fi
#sLaunchDir="${sLaunchDir//include/}"
source "${sLaunchDir}/../include/check-user-privileges" # ./include/test-superuser-privileges.sh moved to ${sLaunchDir}/../include/test-superuser-privileges

sDistBackupFolder="dist-backup"
sEtcFolder=etc
sVarLibDpkg=var/lib/dpkg
sVarLibAptExt=var/lib/apt/extended_states
sDpkgGetSelections="${sDistBackupFolder}/dpkg-get-selections" # dpkg --get-selections '*' # (the quotes are important)
sVarLibAptitudePkgstates="var/lib/aptitude/pkgstates"

getDebianVersion() { 			if [[ -f /etc/debian_version ]]; then 			sDebMainVersion="$(cat /etc/debian_version)"; echo "${sDebMainVersion%%.*}"
								else 											echo "false"; exit 1; fi; }
getDiskBackupFolder() { 		if [[ ! -d /${sDistBackupFolder} ]]; then 		mkdir -p "/${sDistBackupFolder}"; chmod 700 "/${sDistBackupFolder}"; fi; }
backupDpkgSelections() { 		if command -v dpkg &>/dev/null; then 			dpkg --get-selections '*' > "/${sDpkgGetSelections}"; fi; }
backupAptitudePkgstates() { 	if [[ -f /${sVarLibAptitudePkgstates} ]]; then 	tar -czf "/${sDistBackupFolder}/${sVarLibAptitudePkgstates//'/'/'-'}-backup.tar.gz" -C / ${sVarLibAptitudePkgstates}; fi; } #cp -a "${sVarLibAptitudePkgstates}" "${sDistBackupFolder}/"
backupAptExtendedStates() { 	if [[ -f /${sVarLibAptExt} ]]; then 			tar -czf "/${sDistBackupFolder}/${sVarLibAptExt//'/'/'-'}-backup.tar.gz" -C / /${sVarLibAptExt}; fi; } #cp -a "${sVarLibAptExt}" "${sDistBackupFolder}/"
backupEtcFolder() { 			if [[ -d /${sEtcFolder} ]]; then 				tar -czf "/${sDistBackupFolder}/${sEtcFolder}-backup.tar.gz" -C / ${sEtcFolder}; fi; }
backupVarLibDpkg() { 			if [[ -d /${sVarLibDpkg} ]]; then 				tar -czf "/${sDistBackupFolder}/${sVarLibDpkg//'/'/'-'}-backup.tar.gz" -C / ${sVarLibDpkg}; fi; }	
upgradeCheck() {
	apt-get autoremove
	apt-mark showhold | grep -q . && { echo "There are held packages. Please unhold them before proceeding with the upgrade."; exit 1; } # apt-mark hold package_name || apt-mark unhold package_name
	dpkg --audit | grep -q . && { echo "There are broken packages. Please fix them before proceeding with the upgrade."; exit 1; }
	if apt-get list '?obsolete' 2>/dev/null | grep -q .; then
		echo "There are obsolete packages. Please remove them before proceeding with the upgrade."
		apt-get autoremove
		exit 1
	fi
	if apt-get list '?orphaned' 2>/dev/null | grep -q .; then
		echo "There are orphaned packages. Please remove them before proceeding with the upgrade."
		apt-get autoremove
		exit 1
	fi
	if apt-get list '?config-files' 2>/dev/null | grep -q .; then
		echo "There are packages with only configuration files remaining. Please purge them before proceeding with the upgrade."
		apt-get autoremove
		exit 1
	fi
}
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
