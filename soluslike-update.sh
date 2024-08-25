#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

update_solus() {
    if ! command -v freebsd-update; then
        if command -v sudo; then
            sudo eopkg update && sudo eopkg upgrade
        elif test $UID -eq 0; then
            eopkg update && eopkg upgrade
        fi
    fi 
}
clean_solus() {
    if command -v sudo; then    sudo eopkg remove --unused && sudo eopkg remove-orphans && sudo eopkg clean
    elif test $UID -eq 0; then  eopkg remove --unused && eopkg remove-orphans && eopkg clean
    fi
}
main_soluslike_update() {
    if ! command -v eopkg; then 
	    echo -e "\t>>> eopkg command not found, exit now !!!"
        exit 1
    else
        echo -e "\t>>> eopkg command found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4.shutdown vm"
    fi
    #update_freebsd
    update_solus && clean_solus && poweroff
}

main_soluslike_update
