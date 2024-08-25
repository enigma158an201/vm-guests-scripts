#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

update_dnf() {
    sudo dnf update && sudo dnf full-upgrade
}
clean_dnf() {
    sudo dnf autoremove && sudo dnf clean
}
main_rockylinux_update() {
    if ! command -v dnf; then 
	    echo -e "\t>>> dnf not found, exit now !!!"
        exit 1
    else
        echo -e "\t>>> dnf found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
    fi
    update_dnf && clean_dnf && shutdown 0
}

main_rockylinux_update
