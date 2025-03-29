#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

#https://www.ssh-audit.com/hardening_guides.html#debian_12

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/../include/check-user-privileges" #source "${sLaunchDir}/include/set-common-settings.sh"

sSshUserFolder=.ssh
sSshAliasConfig=${sSshUserFolder}/config
sSshAliasConfigd=${sSshAliasConfig}.d
sSshAuthKeys=${sSshUserFolder}/authorized_keys
sSshAuthKeyKonnectVM="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9rbQRZGsbwIi+EIgn3C8s59shJ1eMirAnXHzz8wStk vbox@konnect"

sSshRepoSource="${sLaunchDir}/../src/home/user"
sSshRepoConf=${sSshRepoSource}/${sSshUserFolder}
sSshRepoAliasConfig=${sSshRepoSource}/${sSshAliasConfig}
sSshRepoAliasConfigd=${sSshRepoSource}/${sSshAliasConfigd}
#sSshRepoAuthKeys=${sSshRepoSource}/${sSshAuthKeys}

sSshLocalConf=${HOME}/${sSshUserFolder}
sSshLocalAliasConfig=${HOME}/${sSshAliasConfig}
sSshLocalAliasConfigd=${HOME}/${sSshAliasConfigd}
sSshLocalAuthKeys=${HOME}/${sSshAuthKeys}

installSshAlias() {
	echo -e "\t>>> setup ssh alias config at ${sSshLocalAliasConfig}{,.d/}"
	if [[ -f "${sSshRepoAliasConfig}" ]]; then 		rsync -av "${sSshRepoAliasConfig}" "${sSshLocalAliasConfig}"; fi
	if [[ -d "${sSshRepoAliasConfigd}" ]]; then 	rsync -av "${sSshRepoAliasConfigd}/" "${sSshLocalAliasConfigd}/"; fi
}
installSshKeys() {
	echo -e "\t>>> setup ssh keys at ${sSshLocalConf}"
	echo -e "\t>>> checking ssh authorized_keys keys at ${sSshLocalAuthKeys}"
	if ! test -e "${sSshLocalAuthKeys}"; then 	touch "${sSshLocalAuthKeys}"; fi
	install -o "${USER}" -g "${USER}" -pv truc machin
	for sAliasPubKey in "${sSshRepoConf}"/*.pub; do 
		install -o "${USER}" -g "${USER}" -pv -m 0644 "${sSshRepoConf}/${sAliasPubKey}" "${sSshLocalConf}/${sAliasPubKey}"
		install -o "${USER}" -g "${USER}" -pv -m 0600 "${sSshRepoConf}/${sAliasPubKey/.pub/}" "${sSshLocalConf}/${sAliasPubKey/.pub/}"
	done
}
importSshKeys() {
	echo -e "\t>>> setup ssh authorized_keys at ${sSshLocalConf}"	#ssh-copy-id -i debian_server.pub pragmalin@debianvm
	##for sSshPubKey in "${sSshRepoConf}"/*.pub; do
	#	for sSshAlias in SKY41 testsalonk wtestsalonk #freebox-delta-wan
	#	do
	#		sSshPubKey="to-do-check_if_alias_reachable_and_key_importable"
	#		if true; then 	echo "ssh-copy-id -i \"${sSshPubKey}\" \"${sSshAlias}\""; fi
	#	done
	##done
	if [[ ! -f "${sSshLocalAuthKeys}" ]]; then touch "${sSshLocalAuthKeys}"; fi
	if ! grep -q "${sSshAuthKeyKonnectVM}" "${sSshLocalAuthKeys}"; then echo "${sSshAuthKeyKonnectVM}" >> "${sSshLocalAuthKeys}"; fi
}
updateSshdConfig() {
	echo -e "\t>>> application des fichiers config ssh et sshd"
	suExecCommand "	rsync -av \"$(readlink -f "${sLaunchDir}/../src/etc/ssh/sshd_config.d")/\" /etc/ssh/sshd_config.d/; \
					rsync -av \"$(readlink -f "${sLaunchDir}/../src/etc/ssh/ssh_config.d")/\" /etc/ssh/ssh_config.d/; 
					bash -x -c 'for sSshCrypt in rsa dsa ecdsa; do rm /etc/ssh/ssh_host_*\$sSshCrypt*_key* || true; done'"
	read -rp " "
}
cleanModuli() {
	suExecCommand "	awk '\$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe; \
					mv /etc/ssh/moduli /etc/ssh/moduli.bak; \
					mv /etc/ssh/moduli.safe /etc/ssh/moduli" || true
}
restartSshd() {
	if command -v systemctl &>/dev/null; then 	suExecCommand "bash -c \"for sSshSvc in sshd ssh; do systemctl restart \$sSshSvc.service; done"; fi
}
main_ssh_config() {
	cleanModuli
	updateSshdConfig
	installSshAlias
	#installSshKeys
	importSshKeys #todo: import existing vm ssh keys to host
	restartSshd
}
main_ssh_config