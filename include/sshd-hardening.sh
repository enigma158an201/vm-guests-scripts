#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # -x

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

updateSshdConfig() {
	set -x
	sSshsource="$(readlink -f "$@")"
	echo -e "\t>>> application des fichiers config ssh et sshd"
	for sSshDst in sshd_config.d ssh_config.d; do
		rsync -av "${sSshsource}/${sSshDst}/" "/etc/ssh/${sSshDst}/" 
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
	for sSshSvc in sshd ssh; do
		if command -v systemctl &>/dev/null; then systemctl restart ${sSshSvc}.service || true; fi
		if command -v service &>/dev/null; then service ${sSshSvc} restart || true; fi
		#if command -v /etc/init.d/${sSshSvc} &>/dev/null; then /etc/init.d/${sSshSvc} restart || true; fi
	done
}
mainSshHarderning() {
	sSshsource="$(readlink -f "$@")"
	updateSshdConfig "${sSshsource}"
    cleanModuli
	restartSshd
}
mainSshHarderning "$@"