#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"
source "${sLaunchDir}/include/check-virtual-env"
source "${sLaunchDir}/include/git-self-update"

update_arch() {
	#shellcheck disable=SC2154
	if command -v "${sSuPfx}" &>/dev/null; then 	eval "${sSuPfx} pacman -Syyuu"
	else 											pacman -Syyuu
	fi
}
clean_arch() {
	if command -v "${sSuPfx}" &>/dev/null; then 	if pacman -Qdtq; then eval "pacman -Qdtq | ${sSuPfx} pacman -Rs -"; fi
													eval "${sSuPfx} pacman -Scc --noconfirm" 
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
	if command -v paru &>/dev/null; then 			paru -Sccd --noconfirm
	elif [[ "$(checkRootPermissions)" = "false" ]]; then 
													setup_paru #else exit 1; 
	fi
}
clean_trizen() {
	if command -v trizen &>/dev/null; then 			trizen -Sccd --noconfirm; fi
}
setup_paru() {
	#if [[ ${UID} = 0 ]] || [[ ${UID} = 0 ]]; then exit 1; fi
	cd /tmp || exit
	if command -v "${sSuPfx}" &>/dev/null; then 	eval "${sSuPfx} pacman -S --needed base-devel"
	else 											pacman -S --needed base-devel
	fi
	if false; then 									git clone https://aur.archlinux.org/paru.git
													cd paru || exit
	else 											git clone https://aur.archlinux.org/paru-bin.git
													cd paru-bin || exit
	fi
	makepkg -si
}

main_archlike_update() {	#echo ${sSuPfx}; read -rp ""
	if ! command -v pacman &>/dev/null; then 		echo -e "\t>>> pacman not found, exit now !!!"
													exit 1
	else 											echo -e "\t>>> pacman found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. shutdown vm"
	fi
	updateScriptsViaGit
	update_arch && clean_arch
	bVirtualized="$(checkVirtEnv)" #; echo "${bVirtualized}" 
	if [[ ${bVirtualized} -eq 0 ]]; then 			eval "${sSuPfx} shutdown 0"; fi
}

main_archlike_update
