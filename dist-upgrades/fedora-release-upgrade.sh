#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git
# refer to:
# https://docs.fedoraproject.org/en-US/quick-docs/upgrading-fedora-offline/

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/../include/check-user-privileges"
#source "${sLaunchDir}/../include/check-virtual-env"
source "${sLaunchDir}/../include/git-self-update"

upgrade_refresh_dnf() { suExecCommand "dnf upgrade --refresh"; }
getFedoraRelease() {
	if [[ -f /etc/fedora-release ]]; then 	sFedoraRelease="$(cat /etc/fedora-release)"
											sFedoraRelease="${sFedoraRelease,,//fedora release /}"
											echo "${sFedoraRelease%%(*}"
	else 									echo "false"
											exit 1
	fi
}
switchFedoraRelease() {
	sRelease="$(getFedoraRelease)"
	sNextRelease=$((sRelease + 1 )) #"$(echo "${sRelease}" | awk -F. '{print $1+1}')"
	echo "${sNextRelease}"
	#if [[ -n ${sRelease} ]]; then 			#suExecCommand "dnf --setopt=deltarpm=false --assumeyes --refresh --releasever=${sNextRelease}"
	#										suExecCommand "dnf system-upgrade download --releasever=${sNextRelease}"; fi #--allowerasing #--best #--setopt=keepcache=1
}
upgradeFedoraRelease() {	if [[ -n ${sRelease} ]]; then 			suExecCommand "dnf system-upgrade reboot"; fi; }
bootloaderReinstall() {	#suExecCommand "dnf install grub2-efi shim" || suExecCommand "dnf install grub2-pc"
	if [[ ! -d /sys/firmware/efi/efivars ]]; then 					sBootPart=$(suExecCommand "mount | grep \"/boot \"") # | awk '{print $1}'")
																	#sBootPart=$(echo "${sBootPart}" | sed 's/\/dev\///')
																	#sBootDisk=$(echo "${sBootPart}" | sed 's/[^0-9]*//g')
																	sBootPart=${sBootPart%% *}
																	sBootDisk=${sBootPart//[0-9]/}
																	echo "${sBootDisk}"
																	#suExecCommand "grub2-install ${sBootDisk}"
	#else 															echo ; 
	fi
}
postUpgradeFedoraRelease() {
	if [[ $(getFedoraRelease) = $(fetchFedoraCurrent) ]]; then 		
																	suExecCommand "dnf install rpmconf"
																	suExecCommand "rpmconf -a"
																	bootloaderReinstall
																	suExecCommand "dnf install remove-retired-packages"
																	if suExecCommand "dnf repoquery --duplicates"; then 
																		suExecCommand "dnf remove --duplicates"
																	fi
																	#sudo dnf list --extras
																	#sudo dnf remove $(sudo dnf repoquery --extras --exclude=kernel,kernel-\*,kmod-\*)
																	#sudo dnf autoremove
																	removeOldKernels
																	#sudo dnf install clean-rpm-gpg-pubkey
																	#sudo clean-rpm-gpg-pubkey
																	#sudo dnf install symlinks
																	#sudo symlinks -r /usr | grep dangling && sudo dnf install symlinks
																	#sudo rm /boot/*rescue*
																	#sudo kernel-install add "$(uname -r)" "/lib/modules/$(uname -r)/vmlinuz"
	fi
}
removeOldKernels() {	#suExecCommand "dnf remove $(dnf repoquery --installonly --latest-limit=-2 -q)";
	#shellcheck disable=SC2207
	old_kernels=($(dnf repoquery --installonly --latest-limit=-1 -q))
	if [[ "${#old_kernels[@]}" -eq 0 ]]; then 	echo "No old kernels found"; exit 0; fi
	if ! dnf remove "${old_kernels[@]}"; then 	echo "Failed to remove old kernels"; fi #exit 1
	echo "Removed old kernels" #; exit 0
}
fetchFedoraCurrent() { # Fetch the HTML content from the redirected mirror
	url="https://download.fedoraproject.org/pub/fedora/linux/releases/"
	html=$(curl -Ls "${url}")
	# Extract the highest two-digit number
	highest_version=$(echo "${html}" | grep -oE '[0-9]{2}/' | sed 's#/##' | sort -n | tail -1)
	echo "${highest_version}"	# Set the environment variable	#export VERSION=${highest_version}	#echo "VERSION=$#"
}
main() {
	# 1st run recommended to update old distro 
	upgrade_refresh_dnf
	switchFedoraRelease
	#upgradeFedoraRelease
	# 2nd run to version upgrading
	#upgradeDebianDist
}
main
