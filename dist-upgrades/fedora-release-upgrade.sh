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

upgradeRefreshDnf() { suExecCommand "dnf upgrade --refresh"; }
getFedoraRelease() {
	if [[ -f /etc/fedora-release ]]; then 	sFedoraRelease="$(cat /etc/fedora-release)"
											sFedoraRelease="${sFedoraRelease,,}"
											sFedoraRelease="${sFedoraRelease//fedora release /}"
											echo "${sFedoraRelease%%(*}"
	else 									echo "false"
											exit 1
	fi
}
switchDownloadFedoraRelease() {
	sRelease="$(getFedoraRelease)"
	sCurrent=$(fetchFedoraCurrent)
	if [[ ${sRelease} = "${sCurrent}" ]]; then 	echo "Already on the latest version: ${sRelease}" #; exit 0
	elif [[ $(( sCurrent - sRelease )) -eq 1 ]]; then iOffset=1
	elif [[ $(( sCurrent - sRelease )) -gt 1 ]]; then iOffset=2
	fi #	else 										echo "Current version: ${sRelease}"
	sNextRelease=$(( sRelease + iOffset )) #"$(echo "${sRelease}" | awk -F. '{print $1+1}')"
	echo -e "\t>>> Your release is ${sRelease}, upgrade is available to release ${sNextRelease}, and the current stable release is ${sCurrent}"
	if [[ -n ${sRelease} ]]; then 			read -rp "Do you want to upgrade to ${sNextRelease} (y/n)? " -n 1 sYesNo								
		if [[ ${sYesNo} = "y" ]]; then 		#suExecCommand "dnf --setopt=deltarpm=false --assumeyes --refresh --releasever=${sNextRelease}"
			suExecCommand "dnf install tmux"
			suExecCommand "tmux new-session -A -s supgradeF -n wupgradeF -d"
			suExecCommand "tmux -attach-session -t supgradeF"
			if true; then 					suExecCommand "tmux send-keys -t supgradeF 'dnf system-upgrade download --releasever=${sNextRelease} --allowerasing --best' C-m" #--setopt=keepcache=1
											suExecCommand "tmux send-keys -t supgradeF 'dnf system-upgrade --reboot' C-m" || \
											suExecCommand "tmux send-keys -t supgradeF 'dnf system-upgrade reboot' C-m"
			else 							#suExecCommand "dnf install fedora-upgrade" && suExecCommand "fedora-upgrade"											
											suExecCommand "tmux send-keys -t supgradeF 'dnf install fedora-upgrade' C-m"
											suExecCommand "tmux send-keys -t supgradeF 'fedora-upgrade --releasever=${sNextRelease}' C-m"
			fi
			#suExecCommand  "tmux kill-session -t supgradeF"
		else 								echo -e "\t>>> Upgrade cancelled, exiting now"
											return 1
											#exit 0
		fi
	fi
}
upgradeFedoraRelease() { if [[ -n ${sRelease} ]]; then suExecCommand "dnf system-upgrade reboot"; fi; }
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
																	autoremoveOldPkgs
																	removeOldKernels
																	#sudo dnf install clean-rpm-gpg-pubkey
																	#sudo clean-rpm-gpg-pubkey
	fi
}
autoremoveOldPkgs() {
	suExecCommand "dnf install remove-retired-packages" || true
	if suExecCommand "dnf repoquery --duplicates"; then 			suExecCommand "dnf remove --duplicates" || true; fi
	if suExecCommand "dnf list --extras"; then 						suExecCommand "dnf remove $(sudo dnf repoquery --extras --exclude=kernel,kernel-\*,kmod-\*)"; fi
	suExecCommand "dnf autoremove --skip-broken" || true
	suExecCommand "dnf install symlinks"
	suExecCommand "symlinks -r /usr | grep dangling" && suExecCommand "symlinks -r -d /usr"
}
removeOldKernels() {	#suExecCommand "dnf remove $(dnf repoquery --installonly --latest-limit=-2 -q)";
	#shellcheck disable=SC2207
	old_kernels=($(dnf repoquery --installonly --latest-limit=-1 -q))
	if [[ "${#old_kernels[@]}" -eq 0 ]]; then 	echo "No old kernels found"; return 0; fi 			#exit 0
	if ! dnf remove "${old_kernels[@]}"; then 	echo "Failed to remove old kernels"; return 1; fi 	#exit 1
	echo "Removed old kernels" #; exit 0
}
rescueKernelReinstall() {
	suExecCommand "rm /boot/*rescue*" || true
	suExecCommand "kernel-install add \"\$(uname -r)\" \"/lib/modules/\$(uname -r)/vmlinuz\""
}
fetchFedoraCurrent() { # Fetch the HTML content from the redirected mirror
	url="https://download.fedoraproject.org/pub/fedora/linux/releases/"
	html=$(curl -Ls "${url}")
	# Extract the highest two-digit number
	highest_version=$(echo "${html}" | grep -oE '[0-9]{2}/' | sed 's#/##' | sort -n | tail -1)
	echo "${highest_version}"	# Set the environment variable	#export VERSION=${highest_version}	#echo "VERSION=$#"
}
main() {
	autoremoveOldPkgs
	removeOldKernels
	# 1st run recommended to update old distro
	upgradeRefreshDnf
	{ switchDownloadFedoraRelease || exit 1; } && upgradeFedoraRelease
	# 2nd run to version upgrading
	rescueKernelReinstall
}
main
