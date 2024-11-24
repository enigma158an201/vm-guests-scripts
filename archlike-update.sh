#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

update_arch() {
	sudo pacman -Syyuu
}
clean_arch() {
	sudo pacman -Scc
	clean_trizen
	clean_paru
}
clean_paru() {
	if command -v paru &>/dev/null; then 
		paru -Sccd
	else
		setup_paru
	fi
}
clean_trizen() {
	if command -v trizen &>/dev/null; then trizen -Sccd; fi
}
setup_paru() {
	cd /tmp
	sudo pacman -S --needed base-devel
	git clone https://aur.archlinux.org/paru.git
	cd paru
	makepkg -si
}
updateScriptsViaGit(){
	./git-pull-refresh.sh
}

main_archlike_update() {
	if ! command -v pacman; then 
		echo -e "\t>>> pacman not found, exit now !!!"
		exit 1
	else
		echo -e "\t>>> pacman found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
	fi
	updateScriptsViaGit
	update_arch && clean_arch && shutdown 0
}

main_archlike_update
