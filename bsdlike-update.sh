#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 
update_freebsd() {
    if ! command -v freebsd-update; then
        sudo freebsd-update fetch && sudo freebsd-update install
    fi 
}
update_bsd() {
    sudo pkg update -f && sudo pkg upgrade 
}
clean_bsd() {
    sudo pkg autoremove && sudo pkg clean
}
main_bsdlike_update() {
    if ! command -v pkg; then 
	    echo -e "\t>>> pkg command not found, exit now !!!"
        exit 1
    else
        echo -e "\t>>> pkg command found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
    fi
    update_freebsd
    update_bsd && clean_bsd && poweroff
}

main_bsdlike_update
