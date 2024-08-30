#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

update_apt() {
    if command -v sudo; then
        sudo apt-get update && sudo apt-get full-upgrade
    else
        apt-get update && apt-get full-upgrade
    fi
}
clean_apt() {
    if command -v sudo; then
        sudo apt-get autoremove --purge && sudo apt-get clean
    else
        apt-get autoremove --purge && apt-get clean
    fi
}
main_deblike_update() {
    if ! command -v apt-get || ! command -v apt; then 
	    echo -e "\t>>> apt not found, exit now !!!"
        exit 1
    else
        echo -e "\t>>> apt found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
    fi
    update_apt && clean_apt && shutdown 0
}

main_deblike_update
