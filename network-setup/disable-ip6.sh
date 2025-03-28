#!/usr/bin/env bash

# script by enigma158an201 
set -euo pipefail #; set -x

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

#sLaunchDir="$(dirname "$0")"; if [[ "${sLaunchDir}" = "." ]]; then sLaunchDir="$(pwd)"; elif [[ "${sLaunchDir}" = "include" ]]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"
sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/../include/check-user-privileges"

checkSysctlEnabled() {
	if sysctl -a &>/dev/null; then 			echo -e "\t>>> sysctl is enabled"; 		return 0
	else 									echo -e "\t>>> sysctl is not enabled"; 	return 1; fi
}
getSysctlEnabled() { if command -v sysctl &>/dev/null; then echo -e "\t>>> sysctl is enabled"; else echo -e "\t>>> sysctl is not enabled"; fi; }
blacklist-ip6-kernel-modules-sysctl() {
	sIp6BcklDst="/etc/sysctl.d/00-disable-ip6-R13.conf"
	sIp6BcklSrc="${sLaunchDir}/../src${sIp6BcklDst}"
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
blacklist-ip6-NetworkManager() {
	#non persistant, but take effect immediately
	if false; then
		echo -e "\t>>> proceed set disable ipv6 to sysctl kernel parameters"
		suExecCommand "sysctl -w net.ipv6.conf.all.disable_ipv6=1; \
		sysctl -w net.ipv6.conf.default.disable_ipv6=1; \
		sysctl -w net.ipv6.conf.lo.disable_ipv6=1; \
		sysctl -p"
	fi

	if command -v nmcli &>/dev/null && { systemctl is-active NetworkManager || systemctl is-enabled NetworkManager; }; then
		# all=$(LC_ALL=C nmcli dev status | tail -n +2); first=${all%% *}; echo "$first"
		echo -e "\t>>> proceed set disable ipv6 to network manager" ## $(nmcli connection show | awk '{ print $1 }')
		# be careful with connection names including spaces
		suExecCommand "for ConnectionName in $(LC_ALL=C nmcli dev status | tail -n +2 | grep -Eo '^[^ ]+'); do  
			nmcli connection modify \"\$ConnectionName\" ipv6.method disabled || true ; 
		done"
	fi
	#if (systemctl status systemd-networkd); then
		##sed -i '/[Network]/ s/"$/nLinkLocalAddressing=ipv4"/' /etc/systemd/networkd.conf; fi
		#if (! grep '^LinkLocalAddressing=ipv4' /etc/systemd/networkd.conf); then	suExecCommand sed -i '/^\[Network\].*/a LinkLocalAddressing=ipv4 ' /etc/systemd/networkd.conf ;fi 
	#fi
}

main() {
	if ! checkSysctlEnabled; then
		echo -e "\t>>> sysctl is not enabled, exiting..."
		exit 1
	fi
	blacklist-ip6-kernel-modules-sysctl
	applySysctl
	blacklist-ip6-NetworkManagement
}
main