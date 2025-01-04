#!/usr/bin/env bash

#https://easylinuxtipsproject.blogspot.com/p/clean-mint.html
#https://easylinuxtipsproject.blogspot.com/p/speed-mint.html

set -euo pipefail

checkPrivileges() {
	if [[ ${UID} = 0 ]] || [[ ${EUID} = 0 ]]; then echo "true"; else echo "false"; fi
}
cachesDirectoryClean() { #find ~/.cache/ -type f -atime +365 -delete #rm -rfv ~/.cache/thumbnails
	#for sFolder in /home /root /var; do
		#find ${sFolder} -type f -iwholename "*cache/*" -mtime +365 -delete # use mtime if noatime enabled, else atime
	#done
	#find / -type d \( -name "cache" -o -name ".cache" \) 2>/dev/null
	for sFolder in /home/* /root; do #		for sSubFolder in .cache .cpan; do #${sSubFolder}
		if test -d "${sFolder}/.cache/"; then 		find "${sFolder}/.cache/" -type f -mtime +365 -delete	# use mtime if noatime enabled, else atime
													find "${sFolder}/.cache/" -type d -empty -delete
		fi 
	done #done
	#shellcheck disable=SC2043
	for sFolder in /var; do
		if test -d "${sFolder}/cache/"; then 		find "${sFolder}/cache/" -type f -mtime +365 -delete 	# use mtime if noatime enabled, else atime
													find "${sFolder}/cache/" -type d -empty -delete
		fi 
	done
}
cpanDirectoryClean() {
	for sFolder in /home/* /root; do
		if test -d "${sFolder}/.cpan/build/"; then 	find "${sFolder}/.cpan/build/" -maxdepth 1 -type d -mtime +365  -exec rm -r {} \; #-delete
													find "${sFolder}/.cpan/build/" -type d -empty -delete
		fi 
	done
}
aptRemoveUnused() {
	apt-get autoremove --purge
	apt-get purge ~c
	if apt-get distclean; then echo ""; else apt-get autoclean; fi
}
aptRemoveForeignFonts() {
	if command -v apt-get &>/dev/null; then 	apt-get remove "fonts-noto*"
												apt-get install fonts-noto-mono fonts-noto-unhinted fonts-noto-color-emoji
	fi
	if command -v apt-get &>/dev/null; then 	dpkg-reconfigure fontconfig; fi
}
pacmanRemoveUnused() {
	#shellcheck disable=SC2046
	while pacman -Qdtq &>/dev/null; do
		pacman -Rs $(pacman -Qdtq)
		pacman -Scc
	done
}
flatpakRemoveUnused() {
	if command -v flatpak &>/dev/null; then 	flatpak uninstall --unused; fi
}
lessSystemdLogs() {
	if command -v journalctl &>/dev/null; then
		journalctl --vacuum-size=40M
		sed -i 's/#SystemMaxUse=/SystemMaxUse=100M/' /etc/systemd/journald.conf
		sed -i 's/#SystemMaxFiles=100/SystemMaxFiles=7/g' /etc/systemd/journald.conf
		journalctl --rotate
	fi
}
lessSyslogLogs() {
	if command -v rsyslogd &>/dev/null; then
		sed -i 's/rotate 7/rotate 1/g' /etc/logrotate.d/rsyslog
		sed -i 's/rotate 4/rotate 1/g' /etc/logrotate.d/rsyslog
		sed -i 's/weekly/daily/g' /etc/logrotate.d/rsyslog
		sed -i 's/rotate 4/rotate 1/g' /etc/logrotate.conf
		sed -i 's/weekly/daily/g' /etc/logrotate.conf
	fi
}
lessFirewallLogs() {
    if command -v ufw &>/dev/null; then 	ufw logging low; fi #ufw logging off
}

mainCleanUp() {
	if checkPrivileges; then
		cachesDirectoryClean
		cpanDirectoryClean
		if command -v apt-get &>/dev/null; then 	aptRemoveForeignFonts && aptRemoveUnused;	# apt clean
		elif command -v pacman &>/dev/null; then 	pacmanRemoveUnused; fi
		flatpakRemoveUnused																		# flatpak clean
		lessSystemdLogs 																		# clean logs: 	systemd
		lessSyslogLogs																			#				rsyslog
		lessFirewallLogs																		#				ufw
	fi
}
mainCleanUp