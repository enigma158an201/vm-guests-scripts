# shellcheck shell=bash

# files
	alias ll="ls -lA --color=auto" # long listing
	alias ..='cd ..'

# network
	alias gg="ping -c 5 google.com" 
	if command -v netstat &>/dev/null; then 		alias myports='netstat -tulanp'
	elif command -v ss &>/dev/null; then 			alias myports='ss -tulanp'; fi
	if command -v nmap &>/dev/null; then 			alias flic="nmap -v -Pn -A"; fi
	# web server
	if command -v python3 &>/dev/null; then 		alias start-www-server-python="python3 -m http.server 8000"; fi

# vnc ssh tunnels & other remote connection software
	if ! command -v newkeyssh &> /dev/null; then	alias newkeyssh="cd ~/.ssh || exit 1; ssh-keygen -t ed25519 -C \$USER@\$HOSTNAME"; fi #alias newkeyssh="ssh-keygen -t ed25519 -C "
