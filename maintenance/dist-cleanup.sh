#!/usr/bin/env bash

#https://easylinuxtipsproject.blogspot.com/p/clean-mint.html
#https://easylinuxtipsproject.blogspot.com/p/speed-mint.html

# script by enigma158an201
set -euo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

sLaunchDir="$(readlink -f "$(dirname "$0")")"
sParentDir="$(dirname "${sLaunchDir}")"
source "${sLaunchDir}/include/check-virtual-env" || 	source "${sParentDir}/include/check-virtual-env"
source "${sLaunchDir}/include/check-user-privileges" || source "${sParentDir}/include/check-user-privileges"

cachesDirectoryClean() { #find ~/.cache/ -type f -atime +365 -delete #rm -rfv ~/.cache/thumbnails
	#for sFolder in /home /root /var; do
		#find ${sFolder} -type f -iwholename "*cache/*" -mtime +365 -delete # use mtime if noatime enabled, else atime
	#done
	#find / -type d \( -name "cache" -o -name ".cache" \) 2>/dev/null
	echo -e "\t>>> cleaning old system cache files, if applicable"
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
	echo -e "\t>>> cleaning old cpan builds, if applicable"
	for sFolder in /home/* /root; do
		if test -d "${sFolder}/.cpan/build/"; then 	find "${sFolder}/.cpan/build/" -maxdepth 1 -type d -mtime +365  -exec rm -r {} \; #-delete
													find "${sFolder}/.cpan/build/" -type d -empty -delete
		fi 
	done
}
aptRemoveUnused() {
	echo -e "\t>>> cleaning and purging unused apt packages, if applicable"
	apt-get autoremove --purge || true
	apt-get purge ~c || true
	if apt-get distclean; then echo ""; else apt-get autoclean; fi
}
aptRemoveForeign() {
	echo -e "\t>>> list foreign apt packages, if applicable"
	apt list '?narrow(?installed, ?not(?origin(Debian)))'
	echo -e "\t>>> list foreign apt-forktracer packages, if applicable"
	if command -v apt-forktracer &>/dev/null; then apt-forktracer | sort; fi
}
aptRemoveForeignFonts() {
	echo -e "\t>>> cleaning unused foreign, if applicable"
	if command -v apt-get &>/dev/null; then 		apt-get remove "fonts-noto*"
													apt-get install fonts-noto-mono fonts-noto-unhinted fonts-noto-color-emoji
	fi
	if command -v apt-get &>/dev/null; then 		dpkg-reconfigure fontconfig; fi
}
pacmanRemoveUnused() {
	echo -e "\t>>> cleaning unused pacman packages, if applicable"
	#shellcheck disable=SC2046
	while pacman -Qdtq &>/dev/null; do 				pacman -Rs $(pacman -Qdtq)
													pacman -Scc
	done
}
flatpakRemoveUnused() {
	echo -e "\t>>> cleaning unused flatpak packages, if applicable"
	if command -v flatpak &>/dev/null; then 		flatpak uninstall --unused; fi
}
lessSystemdLogs() {
	echo -e "\t>>> cleaning old systemd log files and apply new settings, if applicable"
	if command -v journalctl &>/dev/null; then 		journalctl --vacuum-size=100M
													sed -i 's/#SystemMaxUse=/SystemMaxUse=100M/' /etc/systemd/journald.conf
													sed -i 's/#SystemMaxFiles=100/SystemMaxFiles=7/g' /etc/systemd/journald.conf
													journalctl --rotate
	fi
}
lessSyslogLogs() {
	echo -e "\t>>> cleaning old rsyslogd log files and apply new settings, if applicable"
	if command -v rsyslogd &>/dev/null; then 		sed -i 's/rotate 7/rotate 1/g' /etc/logrotate.d/rsyslog
													sed -i 's/rotate 4/rotate 1/g' /etc/logrotate.d/rsyslog
													sed -i 's/weekly/daily/g' /etc/logrotate.d/rsyslog
													sed -i 's/rotate 4/rotate 1/g' /etc/logrotate.conf
													sed -i 's/weekly/daily/g' /etc/logrotate.conf
	fi
}
lessFirewallLogs() {
	echo -e "\t>>> cleaning old ufw log files and apply new settings, if applicable"
	if command -v ufw &>/dev/null; then 			ufw logging low; fi #ufw logging off
}

mainCleanUp() {
	if checkRootPermissions; then
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