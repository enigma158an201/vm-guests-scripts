#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # -x

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

updateSshdConfig() {
	sSshsource="$(readlink -f "$(dirname "$@")")"
	echo -e "\t>>> application des fichiers config ssh et sshd"
	for sSshDst in /etc/ssh/sshd_config.d /etc/ssh/ssh_config.d; do
		rsync -av "${sSshsource}/" "${sSshDst}/" 
	done
	for sSshCrypt in /etc/ssh/ssh_host_*sa_key*; do 
		echo "" | tee "${sSshCrypt}" || true
		chattr +i "${sSshCrypt}" || true
	done
	#read -rp " "
}
cleanModuli() {
	echo -e "\t>>> hardening moduli"
	awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
	mv /etc/ssh/moduli /etc/ssh/moduli.bak
    mv /etc/ssh/moduli.safe /etc/ssh/moduli
}
restartSshd() {
	if command -v systemctl &>/dev/null; then 	suExecCommand "bash -c 'for sSshSvc in sshd ssh; do systemctl restart \$sSshSvc.service || true; done'"; fi
}
mainSshHarderning() {
	sSshsource="$(readlink -f "$(dirname "$@")")"
	updateSshdConfig "${sSshsource}"
    cleanModuli
	restartSshd
}
mainSshHarderning "$@"