#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# to allow aliases in script as in `bash -i`

sCommand="$*"
if [[ ! "${1:-}" = "" ]]; then 	sArg=${1,,}; fi
 
sTmuxSession="sky41"
sTmuxWindow="evm"
sUsername=$(whoami)
if [[ "${sUsername,,}" =~ "sky " ]]; then
	sAlias1="mainnet-geth"
	sAlias2="mainnet-prysm"
	sAlias3="mainnet-validator-run"
elif [[ "${sUsername,,}" =~ "gwen" ]] || [[ "${sUsername,,}" =~ "freebox" ]]; then
	sAlias1="watch -n 1 ss -tp"
	sAlias2="watch -n 1 ps aux"
	sAlias3="watch -n 1 netstat -tulanp"
fi

if shopt -q expand_aliases; then
    echo "Aliases are already enabled in this script."
else
    echo "Aliases are not enabled in this script, try to enable aliases."
	shopt -s expand_aliases || exit 1
	source "${HOME}/.bashrc"
fi
#if ! command -v detach; then alias detach='tmux detach'; fi
#if ! command -v attach; then alias attach="tmux -a -t ${sTmuxWindow}"; fi # does not work
#if ! command -v stop; then alias stop='tmux detach'; fi

preCheck() {
	if ! command -v tmux &> /dev/null; then 
		echo -e "\t>>> tmux not found, please install tmux, aborting";
		echo -e "\t>>> Install tmux with \`sudo apt-get install tmux\` command"; read -rp "(y/N) ?" -n 1 sTmuxInstall
		if [[ ! "${sTmuxInstall^^}" = "N" ]] && [[ ! "${sTmuxInstall}" = "" ]]; then 	
			if sudo apt-get install tmux; then
				echo -e "\t>>> install tmux success, you can restart the command you entered:\n\`${sCommand}\`"
			fi
		fi
		exit 1
	fi
	if ! command -v tput &> /dev/null; then
		echo -e "\t>>> tput not found, please install tput, aborting";
		echo -e "\t>>> Install tput with \`sudo apt-get install ncurses-bin\` command"; read -rp "(y/N) ?" -n 1 sTputInstall
		if [[ ! "${sTputInstall^^}" = "N" ]] && [[ ! "${sTputInstall}" = "" ]]; then 	
			if sudo apt-get install ncurses-bin; then
				echo -e "\t>>> install tmux success, you can restart the command you entered:\n\`${sCommand}\`"
			fi
		fi
		exit 1
	fi
}
stopMainnetTmux() {
	for iWindow in 4 3 2 1; do
	if [[ "$(tmux list-panes | wc -l)" -eq "${iWindow}" ]]; then 	
		tmux send-keys -t "${sTmuxSession}:${sTmuxWindow}.$((iWindow - 1))" C-c
		tmux send-keys -t "${sTmuxSession}:${sTmuxWindow}.$((iWindow - 1))" 'exit' C-m
	fi
	done
}
startMainnetTmux() {
	# Check if the tmux session "${sTmuxSession}" exists, # If it doesn't exist, create a new session named "${sTmuxSession}": tmux new-session -A -s "${sTmuxSession}"
	if ! tmux has-session -t "${sTmuxSession}" 2>/dev/null; then
		echo -e "\t Creating new session ${sTmuxSession}"
		tmux new-session -s "${sTmuxSession}" -d -x "$(tput cols)" -y "$(tput lines)"
	fi
	
	if ! tmux list-windows -t "${sTmuxSession}" | grep "${sTmuxWindow}"; then
		# Create a window named ""${sTmuxWindow}"" if not exists in the "${sTmuxSession}" session
		echo -e "\t Creating new window ${sTmuxWindow} in existing session ${sTmuxSession}"
		tmux new-window -t "${sTmuxSession}": -n "${sTmuxWindow}" #-P 'p1'
	fi

	#iTmuxWindow=$(tmux list-windows | grep -F "${sTmuxWindow}" | cut -d: -f1)
	tmux set-option -g mouse on		#deprecated: tmux set-option -g mouse-select-pane on

	# Split the window into four panes: two panes on the left and two (one higher) on the right
	if [[ "$(tmux list-panes | wc -l)" -eq "1" ]] && { [[ "${TMUX_PANE:-}" = "%1" ]] || [[ "${TMUX_PANE:-}" = "" ]] ;}; then
		tmux select-pane -t "${sTmuxSession}:${sTmuxWindow}.0"
		tmux split-window -h -t "${sTmuxSession}:${sTmuxWindow}"
	fi
	if [[ "$(tmux list-panes | wc -l)" -eq "2" ]] && { [[ "${TMUX_PANE:-}" = "%2" ]] || [[ "${TMUX_PANE:-}" = "" ]] ;}; then
		tmux select-pane -t "${sTmuxSession}:${sTmuxWindow}.0" #-P 'p1'
		tmux split-window -v -t "${sTmuxSession}:${sTmuxWindow}" #-n 'p2'
	fi
	if [[ "$(tmux list-panes | wc -l)" -eq "3" ]] && { [[ "${TMUX_PANE:-}" = "%2" ]] || [[ "${TMUX_PANE:-}" = "" ]] ;}; then
		tmux select-pane -t "${sTmuxSession}:${sTmuxWindow}.2" #-n 'p3'
		tmux split-window -v -t "${sTmuxSession}:${sTmuxWindow}" -l 5 #-p 90 #-t "${sTmuxSession}"
	fi
	if [[ "$(tmux list-panes | wc -l)" -eq "4" ]]; then
		# Execute specific commands in each pane: 0 1 2 are names of panes
		tmux send-keys -t "${sTmuxSession}:${sTmuxWindow}.0" "${sAlias1}" C-m
		tmux send-keys -t "${sTmuxSession}:${sTmuxWindow}.1" "${sAlias2}" C-m
		tmux send-keys -t "${sTmuxSession}:${sTmuxWindow}.2" "${sAlias3}" C-m #validator
	fi
	# alway echo this line at right bottom
	#if [[ "${TMUX_PANE:-}" = "%4" ]]; then
		tmux send-keys -t "${sTmuxSession}:${sTmuxWindow}.3" "echo -e ' > hide tmux (detach and keep running): press ctrl+b then d or enter \`tmux detach\`\n \
		> navigate next|previous window: press ctrl+b then n or press ctrl+b then p\n \
		> kill tmux window: press ctrl+b then & or enter \`tmux kill-window -t ${sTmuxWindow}\`\n \
		> kill tmux session: enter \`tmux kill-session -t ${sTmuxSession}\` (no-keybind)'" C-m
	#fi
	tmux attach-session -t "${sTmuxSession}"	#tmux attach-session -t "${sTmuxSession}" -c "${sTmuxWindow}"	# Attach to the "${sTmuxSession}" session
}
upgradeBinTmuxEvmScript() {
	if command -v evm-tmux.sh &> /dev/null; then
		sTmuxEvmPath=$(command -v evm-tmux.sh) #
		echo "${sTmuxEvmPath}"
	fi
	if true; then
		mkdir -p "${HOME}/bin"
		#if ! test -z "${sTmuxEvmPath:-}"; then 
			LANG=C find "${HOME}" -iwholename '*/straxui-setup/*evm-tmux.sh' -exec install --mode=0755 --compare --target-directory="${HOME}/bin" {} \; 2>/dev/null || true
		#else
			#find "${HOME}" -iwholename '*/straxui-setup/*evm-tmux.sh' -exec install --mode=0755 --preserve-timestamps --target-directory="${HOME}/bin" {} \;
		#fi
	fi
}
main_evm() {
	preCheck
	if [[ "${sArg:-}" = "upgrade" ]] || [[ "${sArg:-}" = "update" ]]; then 	upgradeBinTmuxEvmScript # 1st find git source, and locally installed script, then upgrade if necessary
	elif [[ "${sArg:-}" = "start" ]] || [[ "${sArg:-}" = "" ]]; then 		startMainnetTmux 		# start script
	elif [[ "${sArg:-}" = "stop" ]] || [[ "${sArg:-}" = "kill" ]]; then 	stopMainnetTmux 		# stop script
	fi
}
main_evm