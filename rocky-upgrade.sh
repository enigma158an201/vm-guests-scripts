#!/usr/bin/env bash

# script by enigma158an201
set -euxo pipefail # set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

#https://linux.how2shout.com/five-commands-to-check-the-almalinux-or-rocky-linux-version/

sMajorCurrentVersion=9
sCurrentVersion="$(rpm -E "%{rhel}")"

sLaunchDir="$(readlink -f "$(dirname "$0")")"
sParentDir="$(dirname "${sLaunchDir}")"
source "${sLaunchDir}/include/check-user-privileges" || source "${sParentDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env" || 	source "${sParentDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update" || 		source "${sParentDir}/include/git-self-update"

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
	#shellcheck disable=SC2154
	if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} 'dnf update && dnf upgrade'"
	else 										dnf update && dnf upgrade
	fi
}
clean_dnf() {
	if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} 'dnf autoremove && dnf clean all'"
	else 										dnf autoremove && dnf clean all
	fi
}

main_rockylinux_upgrade() {
	if ! command -v dnf; then 					echo -e "\t--> dnf not found, exit now !!!"
												exit 1
	else 										echo -e "\t--> dnf found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
	fi
	updateScriptsViaGit
	update_dnf && clean_dnf #&& shutdown 0
	if [[ ${sCurrentVersion} -lt "${sMajorCurrentVersion}" ]]; then majorReleaseUpgrade; fi	
}

main_rockylinux_upgrade
