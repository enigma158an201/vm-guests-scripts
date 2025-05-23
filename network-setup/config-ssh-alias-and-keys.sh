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

checkPrerequisites() {
	for sBin in sshd ssh ssh-copy-id rsync; do
		if ! command -v "${sBin}" &> /dev/null; then 	echo "${sBin} could not be found, please install it first."; exit 1; fi
	done
}
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
		install -o "${USER}" -g "${USER}" -pv -m 0644 "${sSshRepoConf}/${sAliasPubKey}" "${sSshLocalConf}/${sAliasPubKey}" || \
			install -o "${USER}" -g "wheel" -pv -m 0644 "${sSshRepoConf}/${sAliasPubKey}" "${sSshLocalConf}/${sAliasPubKey}"
		install -o "${USER}" -g "${USER}" -pv -m 0600 "${sSshRepoConf}/${sAliasPubKey/.pub/}" "${sSshLocalConf}/${sAliasPubKey/.pub/}" || \
			install -o "${USER}" -g "wheel" -pv -m 0600 "${sSshRepoConf}/${sAliasPubKey/.pub/}" "${sSshLocalConf}/${sAliasPubKey/.pub/}"
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
mkdirUserSsh() {
	if [[ ! -d "${sSshLocalConf}" ]]; then
		echo -e "\t>>> create ssh user folder ${sSshLocalConf}"
		mkdir -p "${sSshLocalConf}"
		chown "${USER}:${USER}" "${sSshLocalConf}"
		chmod 700 "${sSshLocalConf}"
	fi
}
main_ssh_config() {
	checkPrerequisites
	mkdirUserSsh
	installSshAlias
	#installSshKeys
	importSshKeys #todo: import existing vm ssh keys to host #restartSshd
	suExecCommand "$(readlink -f "${sLaunchDir}/../include/sshd-hardening.sh") $(readlink -f "${sLaunchDir}/../src/etc/ssh/")" #cleanModuli #updateSshdConfig
}
main_ssh_config