#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # -x

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

declare sCmdParameters
sCmdParameters="$*"
declare bSudoGroup
declare bSudoersUser
declare bDoasUser

checkUserSudoOrWheelGroup() {
	#set +x #sUser=${USER}
	sUserGroups="$(groups "${USER}")" 		# la commande id pourrait etre une alternative
	sUserGroups="${sUserGroups##*: }"		# sUserGroups="${`groups ${USER}`##*: }"
	bSudoGroup="false"
	for sGr in sudo wheel; do
		for sGr2 in ${sUserGroups}; do 		if [[ "${sGr}" = "${sGr2}" ]]; then 	bSudoGroup="true"; break; fi; done
		if [[ "${bSudoGroup}" = "true" ]]; then 	break; fi
	done
	echo "${bSudoGroup}"
}

#checkSudoers() {
	#set +x #if false; then sudo -l -U ${USER}; fi
	#if false; then		#printf "sPassword\n" | sudo -S /bin/chmod --help >/dev/null 2>&1
						#if [[ $? -eq 0 ];then 		has_sudo_access="YES"
						#else 						has_sudo_access="NO"; fi
						#echo "Does user `id -Gn` has sudo access?: ${has_sudo_access}"
	#fi
	#if false; then		#`timeout -k 2 2 bash -c "sudo /bin/chmod --help" >&/dev/null 2>&1` >/dev/null 2>&1
						#if [[ $? -eq 0 ];then 		has_sudo_access="YES"
						#else 						has_sudo_access="NO"; fi
						#echo "Does user `id -Gn` has sudo access?: ${has_sudo_access}"
	#fi
	#if false; then sudo --validate; fi
	#if false; then sudo -n true; fi #sudo -l ${USER} -n true
	#bUserSudo=$(sudo -v) # if is empty sudo can be used otherwise not
	#SUDO_ASKPASS=/bin/false sudo -A whoami 2>&1
	#getent group | grep -E 'wheel|sudo'
	#echo "a coder" #true; }
checkSudoers() {
	bUserSudo="$(LANG=C sudo -v -A 2>&1)" #bUserSudo=$(LANG=C sudo -v -A || echo "false") # if is sudo error no SUDO_ASKPASS otherwise not
	keyWord="try setting SUDO_ASKPASS"
	if [[ ${bUserSudo} =~ ${keyWord} ]] || [[ "${bUserSudo}" = "" ]]; then 		bSudoers="true"
	else 																		bSudoers="false"; fi
	echo "${bSudoers}"
} 
checkDoasUser() {					#set +x
	bUserDoas="$(LANG=C timeout -v 1 doas true 2>&1)" #echo "test doas valid user" 
	keyWord="doas: Operation not permitted"
	if [[ ! ${bUserDoas} =~ ${keyWord} ]]; then 								bDoasUser="true"
	else 																		bDoasUser="false"; fi
	echo "${bDoasUser}"
}
getSuCmd() {						#set +x
	if [[ ! "${sSudoPath}" = "false" ]] && { [[ ! "${bSudoGroup}" = "false" ]] || \
		[[ ! "${bSudoersUser}" = "false" ]] ; }; then							sSuCmd="${sSudoPath}" #"/usr/bin/sudo"
	elif [[ ! "${sDoasPath}" = "false" ]] && [[ -f /etc/doas.conf ]] && \
		[[ ! "${bSudoGroup}" = "false" ]]; then									sSuCmd="${sDoasPath}" #"/usr/bin/doas"
	else																		sSuCmd="su -p -c"; fi #"su - -p -c"
	echo "${sSuCmd}"
}
getSuCmdNoPreserveEnv() {			#set +x
	if [[ ! "${sSudoPath}" = "false" ]] && { [[ ! "${bSudoGroup}" = "false" ]] || \
		[[ ! "${bSudoersUser}" = "false" ]] ; }; then							sSuCmd="${sSudoPath}" #"/usr/bin/sudo"
	elif [[ ! "${sDoasPath}" = "false" ]] && [[ -f /etc/doas.conf ]] && \
		[[ ! "${bSudoGroup}" = "false" ]]; then									sSuCmd="${sDoasPath}" #"/usr/bin/doas"
	else																		sSuCmd="su - -c"; fi #"su - -p -c"
	echo "${sSuCmd}"
}
suExecCommand() {
	sCommand="$*"
	if ! sSuPfx="$(getSuCmd) "; then 					return 01; fi
	if [[ -n ${sCommand} ]]; then 						if [[ ! "${EUID}" = "0" ]]; then 	eval "${sSuPfx} ${sCommand}"
														elif [[ "${EUID}" = "0" ]]; then 	eval "${sCommand}"; fi
	else 												export sSuPfx
	fi
}
suExecCommandNoPreserveEnv() {
	sCommand="$*"
	if ! sSuPfxNoEnv="$(getSuCmdNoPreserveEnv) "; then 	return 01; fi
	if [[ -n ${sCommand} ]]; then 						if [[ ! "${EUID}" = "0" ]]; then 	eval "${sSuPfxNoEnv} ${sCommand}"
														elif [[ "${EUID}" = "0" ]]; then 	eval "${sCommand}"; fi
	else 												export sSuPfxNoEnv
	fi
}

main_SU(){
	sSudoPath="$(command -v sudo || echo "false")"
	sDoasPath="$(command -v doas || echo "false")"
	if [[ ! "${sSudoPath}" = "false" ]]; then 			bSudoGroup="$(checkUserSudoOrWheelGroup)"
														bSudoersUser="$(checkSudoers)"
	else 												bSudoGroup="false"; bSudoersUser="false"; fi
	if [[ ! "${sDoasPath}" = "false" ]]; then 			bDoasUser="$(checkDoasUser)"
	else 												bDoasUser="false"; fi				#suQuotes="$(getSuQuotes)"
	#if [[ -n "${sCmdParameters}" ]]; then 				
	suExecCommand "${sCmdParameters}" || suExecCommandNoPreserveEnv "${sCmdParameters}"
	#else 												echo ; fi
}
main_SU
