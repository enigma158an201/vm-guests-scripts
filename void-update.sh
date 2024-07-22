#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

update_void() {
    sudo xbps-install -Su
}
clean_void() {
    sudo xbps-remove -yO
}
main_void_update() {
    if ! command -v xbps-install || ! command -v xbps-remove; then 
	    echo -e "\t>>> xbps not found, exit now !!!"
        exit 1
    else
        echo -e "\t>>> xbps found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
    fi
    update_void && poweroff # && clean_void && shutdown 0
}

main_void_update
