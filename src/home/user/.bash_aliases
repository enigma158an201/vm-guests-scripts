# shellcheck shell=bash

# vnc ssh tunnels & other remote connection software
	if ! command -v newkeyssh &> /dev/null; then	alias newkeyssh="cd ~/.ssh || exit 1; ssh-keygen -t ed25519 -C \$USER@\$HOSTNAME"; fi #alias newkeyssh="ssh-keygen -t ed25519 -C "
