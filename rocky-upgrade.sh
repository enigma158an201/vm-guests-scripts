#!/usr/bin/env bash

# script by enigma158an201
set -euxo pipefail # set -euxo pipefail

#https://linux.how2shout.com/five-commands-to-check-the-almalinux-or-rocky-linux-version/

sMajorCurrentVersion=9
sCurrentVersion="$(rpm -E "%{rhel}")"

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update"

majorReleaseUpgrade() {
	if [[ "${sCurrentVersion}" -lt "9" ]]; then
		ROCKY_VERSION=9.4-1.7
		REPO_URL="https://download.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/r"
		RELEASE_PKG="rocky-release-${ROCKY_VERSION}.el9.noarch.rpm"
		REPOS_PKG="rocky-repos-${ROCKY_VERSION}.el9.noarch.rpm"
		GPG_KEYS_PKG="rocky-gpg-keys-${ROCKY_VERSION}.el9.noarch.rpm"
	fi
	if [[ ${sCurrentVersion} -lt "${sMajorCurrentVersion}" ]]; then
		sudo dnf install "${REPO_URL}/${RELEASE_PKG}" "${REPO_URL}/${REPOS_PKG}" "${REPO_URL}/${GPG_KEYS_PKG}"
		#restorecon -Rv /var/lib/rpm
		#rpmdb --rebuilddb
	fi
}
update_dnf() {
	if command -v sudo &>/dev/null; then 	sudo dnf update && sudo dnf upgrade
	else 									dnf update && sudo dnf upgrade
	fi
}
clean_dnf() {
	if command -v sudo &>/dev/null; then 	sudo dnf autoremove && sudo dnf clean all
	else 									dnf autoremove && sudo dnf clean all
	fi
}

main_rockylinux_upgrade() {
	if ! command -v dnf; then 
		echo -e "\t>>> dnf not found, exit now !!!"
		exit 1
	else
		echo -e "\t>>> dnf found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
	fi
	updateScriptsViaGit
	update_dnf && clean_dnf #&& shutdown 0
	if [[ ${sCurrentVersion} -lt "${sMajorCurrentVersion}" ]]; then majorReleaseUpgrade; fi	
}

main_rockylinux_upgrade
