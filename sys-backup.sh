#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

sBackupHost=gwen@192.168.0.53
getBackupFilename() {
	if command -v hostname &>dev/null; then sHostName=$(hostname); else exit 1; fi
	sBackupFile="ssh_backup_${sHostName}_$(date +%Y-%m-%d).tar.gz"
	echo "${sBackupFile}"
}
sBackupFile="$(getBackupFilename)"

main_sys_bakcup() {
    if ! command -v tar &>/dev/null || ! command -v ssh &>/dev/null; then
        echo -e "\t>>> tar or ssh not found, exit now !!!"
    fi
    cd / # THIS CD IS IMPORTANT THE FOLLOWING LONG COMMAND IS RUN FROM /
	#shellcheck disable=SC2029
    tar -cvpz \
    --exclude=/proc \
    --exclude=/tmp \
    --exclude=/mnt \
    --exclude=/dev \
    --exclude=/sys \
    --exclude=/run \
    --exclude=/media \
	--exclude=/var/log \
	--exclude=/var/cache \
	--exclude=/usr/src/linux-headers* \
	--exclude=/home/*/.gvfs \
	--exclude=/home/*/.cache \
	--exclude=/home/*/.local/share/Trash / | ssh "${sBackupHost}" "( cat > \"${sBackupFile}\" )"
}

main_sys_bakcup
