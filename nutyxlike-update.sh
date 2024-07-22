#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail 

update_cards() {
    sudo cards sync && sudo cards upgrade
}
#useless: clean_cards() {}
    
main_cardslike_update() {
    if ! command -v cards; then 
	    echo -e "\t>>> cards not found, exit now !!!"
        exit 1
    else
        echo -e "\t>>> cards found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
    fi
    update_cards && shutdown 0
}

main_cardslike_update
