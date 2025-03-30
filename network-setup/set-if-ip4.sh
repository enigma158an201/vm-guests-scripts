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
appendDhcpcdIfStaticFile() {
	if grep -q "^interface ${sIfName}" /etc/dhcpcd.conf; then #sed -i.old -e "s/^interface ens18$/#&/" /etc/dhcpcd.conf
		echo -e "interface ${sIfName}
		static ip_address=${sAddr4}/24
		static routers=${sGtw4}
		static domain_name_servers=${sDns4}" | ${sSuPfx} tee -a /etc/dhcpcd.conf
	fi
}

disableDhcpInterfaces() {
	echo "Disabling DHCP interfaces"
	if grep -q "^iface $1 inet dhcp" /etc/network/interfaces; then
		sed -i.old -e "s/^iface $1 inet dhcp$/#&/" /etc/network/interfaces
	fi
}
main() {
	if [[ $# -ne 2 ]]; then 	echo "Usage: $0 <interface> <IPv4 address>"
								exit 1
	elif [[ $# -eq 2 ]]; then	if [[ -e /sys/class/net/$1 ]]; then sIfName=$1; else exit 1; fi #validate if the interface exists
								if is_valid_ipv4 "$2"; then sAddr4=$2; else exit 1; fi			#validate if the address is a valid IPv4 address
	fi
	sDns4="194.242.2.3 80.67.169.12"
	sGtw4="192.168.0.254"
	if systemctl is-active networking || systemctl is-enabled networking; then 	createNetworkingIfStaticFile 			#"enp0s3" "192.168.0.107"
																				disableDhcpInterfaces "${sIfName}"; fi 	#disable dhcp lines in /etc/network/interfaces 	
	if systemctl is-active dhcpcd || systemctl is-enabled dhcpcd; then 			appendDhcpcdIfStaticFile; fi 			#append dhcpcd lines in /etc/dhcpcd.conf
	#todo: restart networking service
}
main "$@"