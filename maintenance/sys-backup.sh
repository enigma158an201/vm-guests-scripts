#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sBackupHost=gwen@192.168.0.53
sBackupFolder=/media/VMs/vm-backup

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"
#source "${sLaunchDir}/include/check-virtual-env"
#source "${sLaunchDir}/include/git-self-update"

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
		--exclude=/home/*/.local/share/Trash / | ssh "${sBackupHost}" "( cat > \"${sBackupFolder}${sBackupFile}\" )"
}

main_sys_bakcup
