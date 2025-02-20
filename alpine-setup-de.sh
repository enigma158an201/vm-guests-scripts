#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

sLaunchDir="$(readlink -f "$(dirname "$0")")"
source "${sLaunchDir}/include/check-user-privileges"
#source "${sLaunchDir}/include/check-virtual-env"
#source "${sLaunchDir}/include/git-self-update"

update_setup() {
	#shellcheck disable=SC2154
	if command -v "${sSuPfx}" &>/dev/null; then 		sudo apk update && sudo apk upgrade
	else 										apk update && apk upgrade
	fi
}
clean_setup() {
	if command -v "${sSuPfx}" &>/dev/null; then 		sudo apk -v cache clean
	else 										apk -v cache clean
	fi
}
gvfs_setup() {
	if command -v "${sSuPfx}" &>/dev/null; then 		sudo apk add gvfs-fuse gvfs-mtp gvfs-nfs gvfs-smb
	else 										apk add gvfs-fuse gvfs-mtp gvfs-nfs gvfs-smb
	fi
}
select_option() {
	if ! command -v dialog &>/dev/null; then 
		if command -v "${sSuPfx}" &>/dev/null; then 	sudo apk add dialog
		else 									apk add dialog
		fi
	fi
	HEIGHT=25
	WIDTH=80
	CHOICE_HEIGHT=10
	#BACKTITLE="Backtitle here"
	TITLE="Title here"
	#MENU="Choose one of the following options:"
	#OPTIONS=(1 "Option 1"
	#	 2 "Option 2"
	#	 3 "Option 3")
	OPTIONS="" #i=0;
	for sOpt in "$@"; do
		#i=$((i + 1))
		OPTIONS+=" ${sOpt} ${sOpt} off " #OPTIONS+=" ${sOpt} ${sOpt} " #\n"
	done
	#shellcheck disable=SC2206
	aOPTIONS=( ${OPTIONS} ) #( "${OPTIONS[@]}" )
	#CHOICE=$(dialog --clear \
	#			--backtitle "${BACKTITLE}" \
	#			--title "${TITLE}" \
	#			--menu "${MENU}" ${HEIGHT} ${WIDTH} ${CHOICE_HEIGHT} \
	#			"${aOPTIONS[@]}" \
	#			2>&1 >/dev/tty)
	CHOICE=$(dialog --clear \
				--checklist "${TITLE}" ${HEIGHT} ${WIDTH} ${CHOICE_HEIGHT} \
				"${aOPTIONS[@]}" \
				2>&1 >/dev/tty)
	#clear
	echo "${CHOICE}"
}
gpu_setup() {
	sChoiceGpu=$(select_option xf86-video-amdgpu xf86-video-ati xf86-video-intel xf86-video-nouveau xf86-video-qxl xf86-video-vesa xf86-video-vmware)
	#shellcheck disable=SC2086
	if command -v "${sSuPfx}" &>/dev/null; then 	sudo apk add ${sChoiceGpu}
	else 									apk add ${sChoiceGpu}
	fi
}
input_setup() {
	sChoiceInput=$(select_option xf86-input-evdev xf86-input-libinput xf86-input-synaptics xf86-input-vmmouse xf86-input-wacom)
	#shellcheck disable=SC2086
	if command -v "${sSuPfx}" &>/dev/null; then 	sudo apk add ${sChoiceInput}
	else 									apk add ${sChoiceInput}
	fi
}
sound_setup() {
	if command -v "${sSuPfx}" &>/dev/null; then 	sudo apk add pulseaudio pavucontrol alsa-utils xfce4-pulseaudio-plugin && sudo rc-update add alsa
	else 									setup add pulseaudio pavucontrol alsa-utils xfce4-pulseaudio-plugin && rc-update add alsa
	fi
}
lang_setup() {
	sProfileFr="LANG=fr_FR.UTF-8
LC_CTYPE=fr_FR.UTF-8
LC_NUMERIC=fr_FR.UTF-8
LC_TIME=fr_FR.UTF-8
LC_COLLATE=fr_FR.UTF-8
LC_MONETARY=fr_FR.UTF-8
LC_MESSAGES=fr_FR.UTF-8
LC_ALL="
	sKeyboardFrX="Section \"InputClass\"
	Identifier \"system-keyboard\"
	MatchIsKeyboard \"on\"
	Option \"XkbLayout\" \"fr\"
EndSection"
	if command -v "${sSuPfx}" &>/dev/null; then 	sudo apk add lang
											echo "${sProfileFr}" | sudo tee /etc/profile.d/99-fr.sh
											echo "${sKeyboardFrX}" | sudo tee /etc/X11/xorg.conf.d/30-keyboard.conf
	else 									apk add lang
											echo "${sProfileFr}" | tee /etc/profile.d/99-fr.sh 
											echo "${sKeyboardFrX}" | tee /etc/X11/xorg.conf.d/30-keyboard.conf
	fi
}
main_setup_de() {
	if ! command -v apk &>/dev/null; then 
		echo -e "\t>>> apk not found, exit now !!!"
		exit 1
	else
		echo -e "\t>>> apk found, this script will:\n 1. fetch updates\n 2. install updates\n 3. clean pkg archives\n 4. setup DE \n 5. "
	fi
	update_setup && clean_setup
	if command -v "${sSuPfx}" &>/dev/null; then 	sudo apk add musl-locales
											sudo setup-desktop
											sudo apk add adw-gtk3 adwaita-icon-theme adwaita-xfce-icon-theme
	else 									apk add musl-locales
											setup-desktop
											apk add adw-gtk3 adwaita-icon-theme adwaita-xfce-icon-theme
	fi
	gvfs_setup
	gpu_setup
	input_setup
	sound_setup
	lang_setup
	apk add openrc-settingsd && rc-update add openrc-settingsd boot
}
main_setup_de
