#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

#https://www.ssh-audit.com/hardening_guides.html#debian_12

sLaunchDir="$(dirname "$0")"
source "${sLaunchDir}/../include/check-user-privileges" #source "${sLaunchDir}/include/set-common-settings.sh"

sSshSubFolder=.ssh
sSshAliasConfig=${sSshSubFolder}/config
sSshAliasConfigd=${sSshAliasConfig}.d
sSshAuthKeys=${sSshSubFolder}/authorized_keys

sSshRepoSource="${sLaunchDir}/home/user"
sSshRepoConf=${sSshRepoSource}/${sSshSubFolder}
sSshRepoAliasConfig=${sSshRepoSource}/${sSshAliasConfig}
sSshRepoAliasConfigd=${sSshRepoSource}/${sSshAliasConfigd}
#sSshRepoAuthKeys=${sSshRepoSource}/${sSshAuthKeys}

sSshLocalConf=${HOME}/${sSshSubFolder}
sSshLocalAliasConfig=${HOME}/${sSshAliasConfig}
sSshLocalAliasConfigd=${HOME}/${sSshAliasConfigd}
sSshLocalAuthKeys=${HOME}/${sSshAuthKeys}

installSshAlias() {
	#sLoggedUser=$(whoami)
	echo -e "\t>>> setup ssh alias config at ${sSshLocalAliasConfig}{,.d/}"
	mkdir -p "${sSshLocalAliasConfigd}"
	install -o "${USER}" -g "${USER}" -pv -m 0644 "${sSshRepoAliasConfig}" "${sSshLocalAliasConfig}"
	for sAliasConfigSrc in "${sSshRepoAliasConfigd}"/*; do 
		#install -o "${USER}" -g "${USER}" -pv -m 0644 "${sSshRepoAliasConfigd}/${sAliasConfigSrc}" "${sSshLocalAliasConfigd}/${sAliasConfigSrc}"
		sAliasConfigDst="${sAliasConfigSrc/${sSshRepoSource}/${HOME}}"
		#if [[ ${sAliasConfigDst} =~ ${sLoggedUser} ]]; then
			echo -e "\t>>> proceed file ${sAliasConfigSrc} to ${sAliasConfigDst}"
			install -o "${USER}" -g "${USER}" -pv -m 0644 "${sAliasConfigSrc}" "${sAliasConfigDst}"
		#fi
	done
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
	echo -e "\t>>> setup ssh keys at ${sSshLocalConf}"	#ssh-copy-id -i debian_server.pub pragmalin@debianvm
	#for sSshPubKey in "${sSshRepoConf}"/*.pub; do
		for sSshAlias in SKY41 testsalonk wtestsalonk #freebox-delta-wan
		do
			sSshPubKey="to-do-check_if_alias_reachable_and_key_importable"
			if true; then 	echo "ssh-copy-id -i \"${sSshPubKey}\" \"${sSshAlias}\""; fi
		done
	#done
}
updateSshdConfig() {
	echo -e "\t>>> application des fichiers config sshd"
	declare -a sConfList
	#sConfList=( "$(find "${sLaunchDir}/etc/ssh/sshd_config.d/" -iname '*.conf')" ) #	sConfList=${sConfList//'\n'/' '}
	#sConfList=( $(ls "${sLaunchDir}/etc/ssh/sshd_config.d/*.conf") )
	mapfile -t sConfList < <(find "${sLaunchDir}/../src/etc/ssh/sshd_config.d/" -iname '*.conf')
	export sConfList
	suExecCommand "bash -x -c 'for sSshdConfigFile in ${sConfList[*]}; do
		sSshdConfigFileName=\$(basename \"\${sSshdConfigFile}\")
		sSshdConfigDst=/etc/ssh/sshd_config.d/\${sSshdConfigFileName}
		sSshdConfigSrc=${sLaunchDir}\${sSshdConfigDst}
		if [[ -d \$(dirname \"\${sSshdConfigDst}\") ]] && [[ -f \"\${sSshdConfigSrc}\" ]]; then
			install -o root -g root -m 0744 -pv \${sSshdConfigSrc} \${sSshdConfigDst}
		fi
	done
	for sSshCrypt in rsa dsa ecdsa; do
		rm /etc/ssh/ssh_host_*\$sSshCrypt*_key || true
	done
	systemctl restart sshd.service'"
}
cleanModuli() {
	suExecCommand "awk '\$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe;
	mv /etc/ssh/moduli /etc/ssh/moduli.bak;
	mv /etc/ssh/moduli.safe /etc/ssh/moduli"
}
main_ssh_config() {
	cleanModuli
	updateSshdConfig
	#installSshAlias
	#installSshKeys
	#importSshKeys
	#suExecCommand sshd-config-settings
}
main_ssh_config