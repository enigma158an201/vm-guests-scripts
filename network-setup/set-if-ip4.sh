#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail #; set -x

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git


sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/../include/check-user-privileges"

createNetworkingIfStaticFile() {
	sIfName=$1
	sAddr4=$2
	sNetworkingIfDst="/etc/network/interfaces.d"
	sHostname="$(hostname)"
	#shellcheck disable=SC2154
	echo -e "allow-hotplug ${sIfName}\niface ${sIfName} inet static
	address         ${sAddr4}
	netmask         255.255.255.0
	gateway         192.168.0.254
	dns-nameservers	80.67.169.12 80.67.169.40" | ${sSuPfx} tee "${sNetworkingIfDst}/${sIfName}-${sHostname}"
}
main() {
	createNetworkingIfStaticFile "$@" #"enp0s3" "192.168.0.107"
}
main "$@"