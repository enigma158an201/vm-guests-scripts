#!/usr/bin/env bash

set -euo pipefail #; set -x

#sLaunchDir="$(dirname "$0")"; if [[ "${sLaunchDir}" = "." ]]; then sLaunchDir="$(pwd)"; elif [[ "${sLaunchDir}" = "include" ]]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"
sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"

blacklist-ip6-kernel-modules-sysctl() {
	sIp6BcklDst="/etc/sysctl.d/00-disable-ip6-R13.conf"
	sIp6BcklSrc="${sLaunchDir}${sIp6BcklDst}"
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
	fi
}
main() {
	blacklist-ip6-kernel-modules-sysctl
}
main