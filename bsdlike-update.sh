#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 
update_freebsd() {
    if ! command -v freebsd-update; then
        if command -v sudo; then
            sudo freebsd-update fetch && sudo freebsd-update install
        elif test ${UID} -eq 0; then
            freebsd-update fetch && freebsd-update install
        fi
    fi 
}
update_bsd() {
    if command -v sudo; then    sudo pkg update -f && sudo pkg upgrade
    elif test ${UID} -eq 0; then  pkg update -f && pkg upgrade
    fi
}
clean_bsd() {
    if command -v sudo; then    sudo pkg autoremove && sudo pkg clean
    elif test ${UID} -eq 0; then  pkg autoremove && pkg clean
    fi
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
