#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sLaunchDir="$(readlink -f "$(dirname "$0")")"
if [[ "$(basename "${sLaunchDir}")" = "vm-guests-scripts" ]]; then 
	sParentDir=${sLaunchDir}
else
	sParentDir="$(dirname "${sLaunchDir}")" 
	while [[ "$(basename "${sParentDir}")" != "vm-guests-scripts" ]]; do sParentDir="$(dirname "${sParentDir}")"; done
fi
source "${sParentDir}/include/check-user-privileges"	#source "${sLaunchDir}/include/check-user-privileges" || source "${sParentDir}/include/check-user-privileges"
source "${sParentDir}/include/check-virtual-env" 		#source "${sLaunchDir}/include/check-virtual-env" || 	source "${sParentDir}/include/check-virtual-env"
source "${sParentDir}/include/git-self-update"			#source "${sLaunchDir}/include/git-self-update" || 		source "${sParentDir}/include/git-self-update"

updateArch() {
	#shellcheck disable=SC2154
	if pacman -Qu archlinux-keyring &>/dev/null; then 
		if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} pacman -S --noconfirm archlinux-keyring"; else pacman -S --noconfirm archlinux-keyring; fi
	fi
	if command -v "${sSuPfx}" &>/dev/null; then 	eval "${sSuPfx} pacman -Syyuu"; else pacman -Syyuu; fi
}
cleanArch() {
	if command -v "${sSuPfx}" &>/dev/null && pacman -Qdtq; then eval "pacman -Qdtq | ${sSuPfx} pacman -Rs -" && eval "${sSuPfx} pacman -Scc --noconfirm" 
	elif pacman -Qdtq; then 									pacman -Qdtq | pacman -Rs - && pacman -Scc --noconfirm
	fi
	if [[ "$(checkRootPermissions)" = "false" ]]; then cleanTrizen; cleanParu; fi
}
cleanParu() { if command -v paru &>/dev/null; then paru -Sccd --noconfirm || setupParu; elif [[ "$(checkRootPermissions)" = "false" ]]; then setupParu; fi; } #else exit 1; 
cleanTrizen() { if command -v trizen &>/dev/null; then trizen -Sccd --noconfirm; fi; }
setupParu() { #if [[ ${UID} = 0 ]] || [[ ${UID} = 0 ]]; then exit 1; fi
	cd /tmp || exit
	if command -v "${sSuPfx}" &>/dev/null; then eval "${sSuPfx} pacman -S --needed base-devel"; else pacman -S --needed base-devel; fi
	if true; then sParu=paru; else sParu=paru-bin; fi
	git clone https://aur.archlinux.org/${sParu}.git && { cd ${sParu} || exit; } && makepkg -si
}

mainArchlikeUpdate() {	#echo ${sSuPfx}; read -rp ""
	if ! command -v pacman &>/dev/null; then 		echo -e "\t--> pacman not found, exit now !!!"
													exit 1
	else 											echo -e "\t--> pacman found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
	fi
	updateScriptsViaGit
	updateArch && cleanArch
	bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
	if [[ ${bVirtualized} -eq 0 ]]; then 			eval "${sSuPfx} shutdown 0"; fi
}

mainArchlikeUpdate
