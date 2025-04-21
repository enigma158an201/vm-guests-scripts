#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail #; set -x

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/../include/check-user-privileges"

# Function to check if the input string is a valid IPv4 address
is_valid_ipv4() {
    local ip="$1"
    if [[ ${ip} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r i1 i2 i3 i4 <<< "${ip}" # Split the IP into an array
        if (( i1 >= 0 && i1 <= 255 )) && (( i2 >= 0 && i2 <= 255 )) && (( i3 >= 0 && i3 <= 255 )) && (( i4 >= 0 && i4 <= 255 )); then 	# Check if each octet is between 0 and 255
            echo "${ip} is a valid IPv4 address."
            return 0
        fi
    fi
    echo "${ip} is not a valid IPv4 address."
    return 1
}
createNetworkingIfStaticFile() {
	#todo: confirm the adress mask and gateway
	sNetworkingIfDst="/etc/network/interfaces.d"
	if command -v hostname &>/dev/null; then 	sHostname="$(hostname)"
	elif [[ -f /etc/hostname ]]; then 			sHostname="$(cat /etc/hostname -s)"; fi
	#shellcheck disable=SC2154
	echo -e "allow-hotplug ${sIfName}\niface ${sIfName} inet static
	address         ${sAddr4}
	netmask         255.255.255.0
	gateway         ${sGtw4}
	dns-nameservers	${sDns4}" | ${sSuPfx} tee "${sNetworkingIfDst}/${sIfName}-${sHostname}"
}
disableDhcpNetworkingInterfaces() {
	echo "Disabling DHCP interfaces"
	if grep -q "^iface $1 inet dhcp" /etc/network/interfaces; then
		sed -i.old -e "s/^iface $1 inet dhcp$/#&/" /etc/network/interfaces
	fi
}
createNetworkManagerIfStaticFile() {
	sNetworkingIfDst="/etc/NetworkManager/system-connections"
	if command -v hostname &>/dev/null; then 	sHostname="$(hostname)"
	elif [[ -f /etc/hostname ]]; then 			sHostname="$(cat /etc/hostname -s)"; fi
	echo -e "[connection]\nid=${sIfName}\nuuid=$(uuidgen)\ntype=ethernet\nautoconnect=true\n
[ipv4]\naddress1=${sAddr4}/24,${sGtw4}\ndns=${sDns4}\ndns-priority=100\nmethod=manual\n
[ipv6]\nmethod=ignore" | ${sSuPfx} tee "${sNetworkingIfDst}/${sIfName}-${sHostname}"
	${sSuPfx} chmod 600 "${sNetworkingIfDst}/${sIfName}-${sHostname}"
}
appendDhcpcdIfStaticFile() {
	if [[ -f /etc/dhcpcd.conf ]]; then
		if ! grep -q "^interface ${sIfName}" /etc/dhcpcd.conf; then #sed -i.old -e "s/^interface ens18$/#&/" /etc/dhcpcd.conf
			echo -e "interface ${sIfName}
			static ip_address=${sAddr4}/24
			static routers=${sGtw4}
			static domain_name_servers=${sDns4}" | ${sSuPfx} tee -a /etc/dhcpcd.conf
		fi
	fi
}
createSystemdNetworkdIfStaticFile() {
	sNetworkingIfDst="/etc/systemd/network"
	if command -v hostname &>/dev/null; then 	sHostname="$(hostname)"
	elif [[ -f /etc/hostname ]]; then 			sHostname="$(cat /etc/hostname -s)"; fi
	echo -e "[Match]\nName=${sIfName}\n\n[Network]\nDHCP=no\nAddress=${sAddr4}/24\nGateway=${sGtw4}\nDNS=${sDns4}\nLinkLocalAddressing=no\nIPv6AcceptRA=no" | ${sSuPfx} tee "${sNetworkingIfDst}/${sIfName}-${sHostname}.network"
}
appendRcConfIfStatic() { #https://www.cyberciti.biz/faq/how-to-configure-static-ip-address-on-freebsd/
	sNetworkingIfDst="/etc/rc.conf.d"
	echo -e "config_${sIfName}=\"inet ${sAddr4} netmask ${sMask4}\"" >> "${sNetworkingIfDst}/${sIfName}-${sHostname}"
}
appendResolverConf() {
	sResolverConf="/etc/resolv.conf"
	for i in ${sDns4}; do
		if ! grep -q "^nameserver ${i}" "${sResolverConf}"; then echo "nameserver ${i}" >> "${sResolverConf}"; fi
	done
}
checkSystemdService() { if systemctl is-active "$1" || systemctl is-enabled "$1"; then return 0; else return 1; fi }

main() {
	if [[ $# -ne 2 ]]; then 	echo "Usage: $0 <interface> <IPv4 address>"
								exit 1
	elif [[ $# -eq 2 ]]; then	if [[ -e /sys/class/net/$1 ]]; then sIfName=$1; else exit 1; fi #validate if the interface exists
								if is_valid_ipv4 "$2"; then sAddr4=$2; else exit 1; fi			#validate if the address is a valid IPv4 address
	fi
	sDns4="194.242.2.3 1.1.1.1" #80.67.169.12"
	sGtw4="192.168.0.254"
	sMask4="255.255.255.0"
	if checkSystemdService networking; then 		createNetworkingIfStaticFile 					#"enp0s3" "192.168.0.107"
													disableDhcpNetworkingInterfaces "${sIfName}"	#disable dhcp lines in /etc/network/interfaces
													sRestartSvc=networking; fi
	if checkSystemdService dhcpcd ; then 			appendDhcpcdIfStaticFile						#append dhcpcd lines in /etc/dhcpcd.conf
													sRestartSvc=networking
	fi
	if checkSystemdService NetworkManager; then 	createNetworkManagerIfStaticFile
													sRestartSvc=NetworkManager
	fi
	if checkSystemdService systemd-networkd; then 	createSystemdNetworkdIfStaticFile
													sRestartSvc=systemd-networkd
	fi
	if [[ -n "${sRestartSvc}" ]]; then 				${sSuPfx} systemctl restart "${sRestartSvc}.service"; fi
}
main "$@"