#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

update_arch() {
	if command -v sudo &>/dev/null; then 	sudo pacman -Syyuu
	else 									pacman -Syyuu
	fi
}
clean_arch() {
	if command -v sudo &>/dev/null; then 	pacman -Qdtq | sudo pacman -Rs -
											sudo pacman -Scc --noconfirm 
	else 									pacman -Qdtq | pacman -Rs - 
											pacman -Scc --noconfirm
	fi
	
	sudo pacman -Scc --noconfirm
	clean_trizen
	clean_paru
}
clean_paru() {
	if command -v paru &>/dev/null; then 
		paru -Sccd --noconfirm
	else
		setup_paru
	fi
}
clean_trizen() {
	if command -v trizen &>/dev/null; then trizen -Sccd --noconfirm; fi
}
setup_paru() {
	cd /tmp || exit
	sudo pacman -S --needed base-devel
	if false; then 	git clone https://aur.archlinux.org/paru.git
					cd paru || exit
	else 			git clone https://aur.archlinux.org/paru-bin.git
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
	if ! command -v pacman &>/dev/null; then
		echo -e "\t>>> pacman not found, exit now !!!"
		exit 1
	else
		echo -e "\t>>> pacman found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
	fi
	updateScriptsViaGit
	update_arch && clean_arch && sudo shutdown 0
}

main_archlike_update
