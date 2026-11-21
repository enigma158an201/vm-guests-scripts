#!/usr/bin/env bash

# script by enigma158an201 12/09/2025 @ 23:08, available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git
### this script is intended to be run on apt based Linux distribution to backup the system before a distribution upgrade.###
#https://www.debian.org/releases/trixie/release-notes/upgrading.fr.html

set -euo pipefail

sLaunchDir="$(readlink -f "$(dirname "$0")")"
if [[ "$(basename "${sLaunchDir}")" = "vm-guests-scripts" ]]; then 
	sParentDir=${sLaunchDir}
else
	sParentDir="$(dirname "${sLaunchDir}")" 
	while [[ "$(basename "${sParentDir}")" != "vm-guests-scripts" ]]; do sParentDir="$(dirname "${sParentDir}")"; done
fi
#if [[ "${sLaunchDir}" = "." ]] || [[ "${sLaunchDir}" = "include" ]] || [[ "${sLaunchDir}" = "" ]]; then eval sLaunchDir="$(pwd)"; fi
#sLaunchDir="${sLaunchDir//include/}"
source "${sParentDir}/include/check-user-privileges" #source "${sLaunchDir}/include/check-user-privileges" || source "${sParentDir}/include/check-user-privileges"  # ./include/test-superuser-privileges.sh moved to ${sLaunchDir}/../include/test-superuser-privileges

sDistBkpFld="dist-backup"
sEtcFolder=etc
sVarLibDpkg=var/lib/dpkg
sVarLibAptExt=var/lib/apt/extended_states
sDpkgGetSelections="${sDistBkpFld}/dpkg-get-selections" # dpkg --get-selections '*' # (the quotes are important)
sVarLibAptiPkgsts="var/lib/aptitude/pkgstates"

getDebianVer() { if [[ -f /etc/debian_version ]]; then sDebMainVer="$(cat /etc/debian_version)"; echo "${sDebMainVer%%.*}"; else echo "false"; exit 1; fi; }
getDiskBackupFolder() { if [[ ! -d /${sDistBkpFld} ]]; then mkdir -p "/${sDistBkpFld}"; chmod 700 "/${sDistBkpFld}"; fi; }
backupDpkgSelections() { if command -v dpkg &>/dev/null; then dpkg --get-selections '*' > "/${sDpkgGetSelections}"; fi; }
backupAptitudePkgstates() { if [[ -f /${sVarLibAptiPkgsts} ]]; then tar -czf "/${sDistBkpFld}/${sVarLibAptiPkgsts//'/'/'-'}-backup.tar.gz" -C / ${sVarLibAptiPkgsts}; fi; } #cp -a "${sVarLibAptiPkgsts}" "${sDistBkpFld}/"
backupAptExtendedStates() { if [[ -f /${sVarLibAptExt} ]]; then tar -czf "/${sDistBkpFld}/${sVarLibAptExt//'/'/'-'}-backup.tar.gz" -C / /${sVarLibAptExt}; fi; } #cp -a "${sVarLibAptExt}" "${sDistBkpFld}/"
backupEtcFolder() { if [[ -d /${sEtcFolder} ]]; then tar -czf "/${sDistBkpFld}/${sEtcFolder}-backup.tar.gz" -C / ${sEtcFolder}; fi; }
backupVarLibDpkg() { if [[ -d /${sVarLibDpkg} ]]; then tar -czf "/${sDistBkpFld}/${sVarLibDpkg//'/'/'-'}-backup.tar.gz" -C / ${sVarLibDpkg}; fi; }
upgradeCheck() {
	apt-mark showhold | grep -q . && { echo -e "\t--> There are held packages. Please unhold them before proceeding with the upgrade."; exit 1; } # apt-mark hold package_name || apt-mark unhold package_name
	dpkg --audit | grep -q . && { echo -e "\t--> There are broken packages. Please fix them before proceeding with the upgrade."; exit 1; }
	for sMotif in obsolete orphaned config-files; do
		if apt-get list "?${sMotif}" 2>/dev/null | grep -q .; then
			echo -e "\t--> There are ${sMotif} packages. Script will try autoremove them before proceeding with the upgrade."
			apt-get autoremove
			exit 1
		fi
	done
}
main() {
	getDiskBackupFolder
	backupDpkgSelections
	backupAptitudePkgstates
	backupAptExtendedStates
	backupEtcFolder
	backupVarLibDpkg
	echo -e "\t--> Backup completed and saved to ${sDistBkpFld}"
	upgradeCheck
	echo -e "\t--> System is ready for distribution upgrade.\nYou can now proceed with the distribution upgrade."
}
main
