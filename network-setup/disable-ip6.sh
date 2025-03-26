#!/usr/bin/env bash

# script by enigma158an201 
set -euo pipefail #; set -x

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

#sLaunchDir="$(dirname "$0")"; if [[ "${sLaunchDir}" = "." ]]; then sLaunchDir="$(pwd)"; elif [[ "${sLaunchDir}" = "include" ]]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"
sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/../include/check-user-privileges"

blacklist-ip6-kernel-modules-sysctl() {
	sIp6BcklDst="/etc/sysctl.d/00-disable-ip6-R13.conf"
	sIp6BcklSrc="${sLaunchDir}/../${sIp6BcklDst}"
	if [[ ! -f "${sIp6BcklDst}" ]]; then
		echo -e "\t>>> proceed add disable ipv6 file to /etc/sysctl.d/ "
		#shellcheck disable=SC2154
		eval "${sSuPfx} mkdir -p \"$(dirname "${sIp6BcklDst}")\""
		eval "${sSuPfx} install -o root -g root -m 0744 -pv ${sIp6BcklSrc} ${sIp6BcklDst}"
	fi
	unset sIp6Bckl{Dst,Src}
}
applySysctl() {
	if command -v update-initramfs &>/dev/null; then 	eval "${sSuPfx} update-initramfs -u -k all"
	elif command -v mkinitcpio &>/dev/null; then 		eval "${sSuPfx} mkinitcpio --allpresets"
	elif command -v dracut &>/dev/null; then 			eval "${sSuPfx} dracut -f --regenerate-all"
	else
		echo -e "\t>>> No initramfs tool found to update initramfs|initrd"
	fi
}
main() {
	blacklist-ip6-kernel-modules-sysctl
	applySysctl
}
main