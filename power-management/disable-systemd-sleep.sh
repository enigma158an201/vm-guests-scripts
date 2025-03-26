#!/usr/bin/env bash

set -euo pipefail #; set -x
sLaunchDir="$(dirname "$0")"
source "${sLaunchDir}/../include/file-edition.sh"

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