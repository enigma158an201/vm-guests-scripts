#!/usr/bin/env bash

# script by enigma158an201
set -euxo pipefail # set -euxo pipefail

#https://linux.how2shout.com/five-commands-to-check-the-almalinux-or-rocky-linux-version/

ROCKY_VERSION=9.4-1.7
REPO_URL="https://download.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/r"
RELEASE_PKG="rocky-release-${ROCKY_VERSION}.el9.noarch.rpm"
REPOS_PKG="rocky-repos-${ROCKY_VERSION}.el9.noarch.rpm"
GPG_KEYS_PKG="rocky-gpg-keys-${ROCKY_VERSION}.el9.noarch.rpm"

update_dnf() {
	if command -v sudo &>/dev/null; then 	sudo dnf update && sudo dnf full-upgrade
	else 									dnf update && sudo dnf full-upgrade
	fi
}
clean_dnf() {
	if command -v sudo &>/dev/null; then 	sudo dnf autoremove && sudo dnf clean
	else 									dnf autoremove && sudo dnf clean
	fi
}
main_rockylinux_upgrade() {
	if ! command -v dnf; then 
		echo -e "\t>>> dnf not found, exit now !!!"
		exit 1
	else
		echo -e "\t>>> dnf found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
	fi
	update_dnf && clean_dnf #&& shutdown 0
	if [[ "$(rpm -E "%{rhel}")" = "9" ]]; then 
		sudo dnf install ${REPO_URL}/${RELEASE_PKG} ${REPO_URL}/${REPOS_PKG} ${REPO_URL}/${GPG_KEYS_PKG}
		#restorecon -Rv /var/lib/rpm
		#rpmdb --rebuilddb
	fi
}

main_rockylinux_upgrade
