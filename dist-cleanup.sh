#!/usr/bin/env bash

#https://easylinuxtipsproject.blogspot.com/p/clean-mint.html
#https://easylinuxtipsproject.blogspot.com/p/speed-mint.html

rm -rfv ~/.cache/thumbnails
flatpak uninstall --unused
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
	if command -v apt-get &>/dev/null; then 	aptRemoveFontsUnused && aptRemoveUnused; fi 	# apt clean

	lessSystemdLogs 																			# clean logs: 	systemd
	lessSyslogLogs																				#				rsyslog
	lessFirewallLogs																			#				ufw
}
mainCleanUp