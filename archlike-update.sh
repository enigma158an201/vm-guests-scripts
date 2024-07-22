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
    if ! command -v pacman; then 
	    echo -e "\t>>> pacman not found, exit now !!!"
        exit 1
    else
        echo -e "\t>>> pacman found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
    fi
    update_arch && clean_arch && shutdown 0
}

main_archlike_update
