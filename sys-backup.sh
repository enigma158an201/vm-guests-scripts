#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

sBackupHost=gwen@192.168.0.53
checkRootPermissions() {
	if [[ ${UID} = 0 ]] || [[ ${EUID} = 0 ]]; then
		echo "true"
	else
		echo "false"
	fi
}
getBackupFilename() {
	if command -v hostname &>/dev/null; then 		sHostName=$(hostname)
	elif command -v hostnamectl &>/dev/null; then 	sHostName=$(hostnamectl hostname)
	elif test -f /etc/hostname; then 				sHostName=$(cat /etc/hostname)
	else exit 1; fi
	sBackupFile="ssh_backup_${sHostName}_$(date +%Y-%m-%d).tar.gz"
	echo "${sBackupFile}"
}
sBackupFile="$(getBackupFilename)"

main_sys_bakcup() {
	if ! command -v tar &>/dev/null || ! command -v ssh &>/dev/null; then
		echo -e "\t>>> tar or ssh not found, exit now !!!"
		exit 1
	fi
	if [[ "$(checkRootPermissions)" = "false" ]]; then
		echo -e "\t>>> root privileges are required, try with either: su | sudo | doas\n\t>>> exit now !!!"
		exit 1
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
		--exclude=/export \
		--exclude=/data* \
		--exclude=/disk* \
		--exclude=/montage-disques \
		--exclude=/net \
		--exclude=/shared* \
		--exclude=/var/log \
		--exclude=/var/cache \
		--exclude=/usr/src/linux-headers* \
		--exclude=/cdrom \
		--exclude=/timeshift \
		--exclude=/home/*/.gvfs \
		--exclude=/home/*/.cache \
		--exclude=/home/*/.local/share/Trash / | ssh "${sBackupHost}" "( cat > \"${sBackupFile}\" )"
}

main_sys_bakcup
