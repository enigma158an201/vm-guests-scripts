#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env"

update_arch() {
	if command -v sudo &>/dev/null; then 			sudo pacman -Syyuu
	else 											pacman -Syyuu
	fi
}
clean_arch() {
	if command -v sudo &>/dev/null; then 			if pacman -Qdtq; then pacman -Qdtq | sudo pacman -Rs -; fi
													sudo pacman -Scc --noconfirm 
	else
		 											if pacman -Qdtq; then pacman -Qdtq | pacman -Rs -; fi 
													pacman -Scc --noconfirm
	fi
	if [[ "$(checkRootPermissions)" = "false" ]]; then 
													clean_trizen
													clean_paru
	fi
}
clean_paru() {
	if command -v paru &>/dev/null; then 
		paru -Sccd --noconfirm
	else
		if [[ "$(checkRootPermissions)" = "false" ]]; then setup_paru; fi #else exit 1; 
	fi
}
clean_trizen() {
	if command -v trizen &>/dev/null; then 			trizen -Sccd --noconfirm; fi
}
setup_paru() {
	#if [[ ${UID} = 0 ]] || [[ ${UID} = 0 ]]; then exit 1; fi
	cd /tmp || exit
	if command -v sudo &>/dev/null; then 			sudo pacman -S --needed base-devel
	else 											pacman -S --needed base-devel
	fi
	if false; then 									git clone https://aur.archlinux.org/paru.git
													cd paru || exit
	else 											git clone https://aur.archlinux.org/paru-bin.git
													cd paru-bin || exit
	fi
	makepkg -si
}
updateScriptsViaGit(){
	set +euo pipefail #in case find cannot access some files or folders
	sTargetScript="$(find ~ -nowarn -type f -iname git-pull-refresh.sh 2>/dev/null)" # -exec {} \;
	set -euo pipefail
	if test -f "${sTargetScript}"; then 
		sGitFolder="$(dirname "${sTargetScript}")"
		cd "${sGitFolder}" || exit 1
		bash -x "${sTargetScript}"
	fi
}

main_archlike_update() {
	if ! command -v pacman &>/dev/null; then 		echo -e "\t>>> pacman not found, exit now !!!"
													exit 1
	else 											echo -e "\t>>> pacman found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
	fi
	updateScriptsViaGit
	update_arch && clean_arch #&& sudo shutdown 0
	bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
	if [[ ${bVirtualized} -eq 0 ]]; then 			sudo shutdown 0; fi
}

main_archlike_update
