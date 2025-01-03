#!/usr/bin/env bash

#https://easylinuxtipsproject.blogspot.com/p/clean-mint.html
#https://easylinuxtipsproject.blogspot.com/p/speed-mint.html
checkPrivileges() {
	if [[ ${UID} = 0 ]] || [[ ${EUID} = 0 ]]; then echo "true"; else echo "false"; fi
}
cachesRemove() { #find ~/.cache/ -type f -atime +365 -delete #rm -rfv ~/.cache/thumbnails
	for truc in /home /root /var; do
		find ${truc} -type f -iwholename "*cache/*" -mtime +365 -delete # use mtime if noatime enabled
	done
}
aptRemoveUnused() {
	apt-get autoremove --purge
	apt-get distclean
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
	flatpak uninstall --unused
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
		cachesRemove
		if command -v apt-get &>/dev/null; then 	aptRemoveFontsUnused && aptRemoveUnused;	# apt clean
		elif command -v pacman &>/dev/null; then 	pacmanRemoveUnused; fi
		flatpakRemoveUnused																		# flatpak clean
		lessSystemdLogs 																		# clean logs: 	systemd
		lessSyslogLogs																			#				rsyslog
		lessFirewallLogs																		#				ufw
	fi
}
mainCleanUp