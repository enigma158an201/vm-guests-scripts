#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

update_arch() {
    sudo pacman -Syyuu
}
clean_arch() {
    sudo pacman -Scc
}
main_archlike_update() {
	echo -e "\t>>> hello world !!!"
    update_arch && clean_arch && shutdown 0
}

main_archlike_update
