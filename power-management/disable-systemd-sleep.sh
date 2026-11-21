#!/usr/bin/env bash

# script by enigma158an201, available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git
### this script is intended to be run on any Linux distribution to disable systemd sleep and hibernation.###

set -euo pipefail #; set -x

sLaunchDir="$(readlink -f "$(dirname "$0")")"
if [[ "$(basename "${sLaunchDir}")" = "vm-guests-scripts" ]]; then 
	sParentDir=${sLaunchDir}
else
	sParentDir="$(dirname "${sLaunchDir}")" 
	while [[ "$(basename "${sParentDir}")" != "vm-guests-scripts" ]]; do sParentDir="$(dirname "${sParentDir}")"; done
fi
source "${sParentDir}/include/file-edition.sh"	#source "${sLaunchDir}/include/file-edition.sh" || source "${sParentDir}/include/file-edition.sh"

edit_systemd_disable_sleep() {
	sSleepconfDir=/etc/systemd/sleep.conf
	sSleepLines="AllowSuspend=yes AllowHibernation=yes AllowSuspendThenHibernate=yes AllowHybridSleep=yes"
	for sleepLine in ${sSleepLines}; do
		sLineWithoutVal="${sleepLine/yes/}"
		sLineWithoutVal="${sleepLine/no/}"
		#read -rp "${sleepLine}"
		uncomment			"${sLineWithoutVal}"	"${sSleepconfDir}"
		lineNo="${sLineWithoutVal}no"
		setParameterInFile 	"${sSleepconfDir}"		"${sLineWithoutVal}"		"${lineNo}"
	done
	systemctl daemon-reload
}
add_disable_sleep_systemd() {
	install -o root -g root -m 0744 -pv ../src/etc/systemd/sleep.conf.d/no-sleep.conf /etc/systemd/sleep.conf.d/no-sleep.conf
}
main_disable_sleep() { # edit_systemd_disable_sleep #deprecated
	add_disable_sleep_systemd
}
main_disable_sleep