#!/usr/bin/env bash

# script by enigma158an201 26/03/2025 @ 11:02
set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

# https://linuxize.com/post/how-to-upgrade-debian-10-to-debian-11/
# /etc/apt/sources.list
# deb http://deb.debian.org/debian bullseye main
# deb-src http://deb.debian.org/debian bullseye main
# deb http://security.debian.org/debian-security bullseye-security main
# deb-src http://security.debian.org/debian-security bullseye-security main
# deb http://deb.debian.org/debian bullseye-updates main
# deb-src http://deb.debian.org/debian bullseye-updates main

sLaunchDir="$(readlink -f "$(dirname "$0")")"
#if [[ "${sLaunchDir}" = "." ]] || [[ "${sLaunchDir}" = "include" ]] || [[ "${sLaunchDir}" = "" ]]; then eval sLaunchDir="$(pwd)"; fi
#sLaunchDir="${sLaunchDir//include/}"
source "${sLaunchDir}/../include/check-user-privileges" # ./include/test-superuser-privileges.sh moved to ${sLaunchDir}/../include/test-superuser-privileges

#for debugging source path purpose
#if true; then exit; fi

sAptSourcesListFile="/etc/apt/sources.list"
sAptSourcesListSubfolder=${sAptSourcesListFile}.d
sSourcesListContent="$(cat "${sAptSourcesListFile}")"
sTiersRepos="$(find ${sAptSourcesListSubfolder} -iwholename '*.list')"
#bHasSudo=$(command -v sudo && echo "true" || echo "false") #bHasDoas=$(command -v doas && echo "true" || echo "false")

getDebianVersion() {
	if [[ -f /etc/debian_version ]]; then 	sDebMainVersion="$(cat /etc/debian_version)"
											echo "${sDebMainVersion%%.*}"
	else 									echo "false"
											exit 1
	fi
}
getNonFreeToNonFreeFirmware() {
	if [[ ${sSourcesListContent} =~ non-free ]] && [[ ! ${sSourcesListContent} =~ non-free-firmware ]]; then
		#if ${bHasSudo}; then 	sudo sed -i 's/ non-free/ non-free non-free-firmware /g' "${sAptSourcesListSubfolder}"
		#elif ${bHasDoas}; then 	doas sed -i 's/ non-free/ non-free non-free-firmware /g' "${sAptSourcesListSubfolder}"
		#else					su - -c "sed -i 's/ non-free/ non-free non-free-firmware /g' ${sAptSourcesListSubfolder}"; fi
		suExecCommandNoPreserveEnv "sed -i 's/ non-free/ non-free non-free-firmware /g' \"${sAptSourcesListFile}\""
	fi
}
upgradeJessieToStretch() {
	suExecCommandNoPreserveEnv "sed -i.old 's/jessie/stretch/g' \"${sAptSourcesListFile}\""
	if [[ -n "${sTiersRepos}" ]]; then 
		for sRepo in ${sTiersRepos}; do 	suExecCommandNoPreserveEnv "sed -i.old 's/jessie/stretch/g' \"${sRepo}\""; done
	fi
	#suExecCommandNoPreserveEnv sed -i 's#/debian-security\ stretch/updates#\ stretch-security#g' ${sAptSourcesListFile}
}
upgradeStretchToBuster() {
	suExecCommandNoPreserveEnv "sed -i.old 's/stretch/buster/g' \"${sAptSourcesListFile}\"" #{,.d/*.list}
	if [[ -n "${sTiersRepos}" ]]; then 
		for sRepo in ${sTiersRepos}; do 	suExecCommandNoPreserveEnv "sed -i.old 's/stretch/buster/g' \"${sRepo}\""; done
	fi
	#suExecCommandNoPreserveEnv sed -i 's#/debian-security\ buster/updates#\ buster-security#g' ${sAptSourcesListFile} 
}
upgradeBusterToBullseye() {
	#suExecCommandNoPreserveEnv sed -i.old 's/buster/bullseye/g' ${sAptSourcesListFile}
	#suExecCommandNoPreserveEnv sed -i.old 's/buster/bullseye/g' ${sAptSourcesListFile}.d/*.list
	suExecCommandNoPreserveEnv "sed -i.old 's/buster/bullseye/g' \"${sAptSourcesListFile}\"" #{,.d/*.list}
	if grep bullseye/updates ${sAptSourcesListFile}; then
		suExecCommandNoPreserveEnv "sed -i 's#/debian-security\ bullseye/updates#\ bullseye-security#g' \"${sAptSourcesListFile}\""
	fi
	if [[ -n "${sTiersRepos}" ]]; then
		for sRepo in ${sTiersRepos}; do 	suExecCommandNoPreserveEnv "sed -i.old 's/buster/bullseye/g' \"${sRepo}\""; done
	fi
}
upgradeBullseyeToBookworm() {
	suExecCommandNoPreserveEnv "sed -i.old 's/bullseye/bookworm/g' \"${sAptSourcesListFile}\""
	if [[ -n "${sTiersRepos}" ]]; then
		for sRepo in ${sTiersRepos}; do 	suExecCommandNoPreserveEnv "sed -i.old 's/bullseye/bookworm/g' \"${sRepo}\""; done	
	fi
	getNonFreeToNonFreeFirmware
}
upgradeBookwormToTrixie() {
	suExecCommandNoPreserveEnv "sed -i.old 's/bookworm/trixie/g' \"${sAptSourcesListFile}\""
	if [[ -n "${sTiersRepos}" ]]; then
		for sRepo in ${sTiersRepos}; do 	suExecCommandNoPreserveEnv "sed -i.old 's/bookworm/trixie/g' \"${sRepo}\""; done
	fi
	getNonFreeToNonFreeFirmware
}
upgradeTrixieToForky() {
	suExecCommandNoPreserveEnv "sed -i.old 's/trixie/forky/g' \"${sAptSourcesListFile}\""
	if [[ -n "${sTiersRepos}" ]]; then
		for sRepo in ${sTiersRepos}; do 	suExecCommandNoPreserveEnv "sed -i.old 's/trixie/forky/g' \"${sRepo}\""; done
	fi
	getNonFreeToNonFreeFirmware
}
upgradeForkyToDuke() {
	suExecCommandNoPreserveEnv "sed -i.old 's/forky/duke/g' \"${sAptSourcesListFile}\""
	if [[ -n "${sTiersRepos}" ]]; then
		for sRepo in ${sTiersRepos}; do 	suExecCommandNoPreserveEnv "sed -i.old 's/forky/duke/g' \"${sRepo}\""; done
	fi
	getNonFreeToNonFreeFirmware
}


upgradeToTesting() {
	#if ${bHasSudo}; then 		sudo sed -i 's/bookworm/testing/g' "${sAptSourcesListSubfolder}" #/etc/apt/sources.list{,.d/*.list}
	#elif ${bHasDoas}; then 		doas sed -i 's/bookworm/testing/g' "${sAptSourcesListSubfolder}"
	#else 						su - -c "sed -i 's/bookworm/testing/g' ${sAptSourcesListSubfolder}"; fi
	suExecCommandNoPreserveEnv "sed -i 's/bookworm/testing/g' \"${sAptSourcesListFile}\""
	getNonFreeToNonFreeFirmware
}
upgradeToSid() {
	suExecCommandNoPreserveEnv "sed -i.old 's/trixie/sid/g' \"${sAptSourcesListFile}\""
	getNonFreeToNonFreeFirmware
}
upgradeSourcesList() {
	if [[ -r /etc/debian_version ]]; then
		debInstalledVersion=$(getDebianVersion)
		if [[ "${debInstalledVersion}" = "8" ]]; then 				upgradeJessieToStretch
		elif [[ "${debInstalledVersion}" = "9" ]]; then 			upgradeStretchToBuster
		elif [[ "${debInstalledVersion}" = "10" ]]; then 			upgradeBusterToBullseye
		elif [[ "${debInstalledVersion}" = "11" ]]; then 			upgradeBullseyeToBookworm
		elif [[ "${debInstalledVersion}" = "12" ]]; then 			upgradeBookwormToTrixie
		elif [[ "${debInstalledVersion}" = "13" ]]; then 			echo "forky not stable at moment of this script version"
																	exit 1 #upgradeBookwormToTrixie
		else 														echo "No stable Release for upgrading to debian $((debInstalledVersion + 1))"
		fi
	else
		echo -e "\\tFile /etc/debian_version doesn't exists"
		exit 1
	fi
}
upgradeDebianDist() {
	if ! env | grep XDG_SESSION_TYPE=tty; then #check tty env
		echo -e "\t>>> Le processus d'upgrade peut prendre selon la vitesse de connexion internet et la performance matériel 30 minutes ou plus."
		echo -e "\t	La mise à jour depuis un environnement graphique est déconseillée, à moins d'avoir pris les dispositions pour empêcher"
		echo -e "\t	le verrouillage de la session graphique (ou d'avoir basculé en session sous le tty ce qui résoud tout probleme graphique),"
		echo -e "\t	Si tel est le cas, bien vérifier que tout écran de veille a bien été désactivé"
		read -rp "continuer (y/N)" -n 1 sConfirmUpgrade
	else
		sConfirmUpgrade="y"
	fi
	if [[ "${sConfirmUpgrade,,}" = "y" ]]; then
		suExecCommandNoPreserveEnv "apt-get autoremove && apt-get update && apt-get upgrade && apt-get full-upgrade && apt-get dist-upgrade && apt-get autoremove" 
	fi
}

main() {
	#1st run recommended to update old distro 
	upgradeDebianDist
	#uncomment next line for non debug purpose
	#upgradeSourcesList
	#2nd run to version upgrading
	upgradeDebianDist
}
main
