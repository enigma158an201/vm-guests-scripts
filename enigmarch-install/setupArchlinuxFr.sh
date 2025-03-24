#!/usr/bin/env bash
# developpé par enigma158an201 le 20/02/2020
set -euxo pipefail

# script available at git repo by cloning: $ git clone https://github.com/enigma158an201/vm-guests-scripts.git

# <>
# A bien lire avant d'aller plus loin
# 1. le programme est prévu pour effacer le disque complet et le partitionner (à voir pour sauter cette partie si souhait utulisateur)
# 2. le script va installer de manière minimale arch / lightDM et XFCE par défaut
# 3. la configuration de connexion wifi n'est pas prise en charge
# 4. A n'utiliser qu'à vos risques et périls
#

# constantes
sTargetGrubLegacy="i386-pc"
sTargetGrubEfi="x86_64-efi"

sBiosBootSize=+2MiB
sBiosBootType=ef02
sEfiPartType=ef00
sBootPartType=8300
sRootPartType=8300
sHomePartType=8302
sSwapPartType=8200

sRootTarget="/"
sMntChrootTarget="/mnt"
sBootTarget="/boot"
sHomeTarget="/home"
sHomeRootTarget="/root"
sEfiTarget="${sBootTarget}/efi"

sDebugPrompt="Appuyer sur Entrée ou Enter pour continuer, CTRL + C pour quitter"
bDebugParts=false
bDebugMount=false
bDebugBaseSetup=false
bDebugBootSetup=false
bDebugLclSetup=false
bDebugPkgbase=true
# bDebugXXXX=false

# FUNCTIONS
comment() {
	local regex="${1:?}"
	local file="${2:?}"
	local comment_mark="${3:-#}"
	sed -ri "s:^([ ]*)(${regex}):\\1${comment_mark}\\2:" "${file}"
}

uncomment() {
	local regex="${1:?}"
	local file="${2:?}"
	local comment_mark="${3:-#}"
	sed -ri "s:^([ ]*)[${comment_mark}]+[ ]?([ ]*${regex}):\\1\\2:" "${file}"
}

# debugPartsPrompt() { if [[ ${bDebugParts} = true ]]; then read -rp "${sDebugPrompt}"; fi }
# debugMountPrompt() { if [[ ${bDebugMount} = true ]]; then read -rp "${sDebugPrompt}"; fi }

fdisk -l													# pour identifier le disque
# voir pour obtenir une double confirmation de l'user avant de continuer confirmUser1 et confirmUser2
# sChrootVarFile=/root/chrootVars
if false; then less install.txt; elinks wiki.archlinux.fr/Installation; fi

# choix du disque cible ou affectation /dev/sda par default
echo -e "indiquer le disque cible:\n!Attention le disque sera intégralement effacé!\n"
read -rp "exemple /dev/sda (valeur par defaut si rien n'est saisi)" sDiskDev
sDiskDev=$(echo "${sDiskDev}" | grep -i -e "/dev/")
if [[ "${sDiskDev}" = "" ]]; then
	if [[ -e "/dev/sda" ]]; then sTargetDisk="/dev/sda"; fi
else
	if [[ -e "${sDiskDev}" ]]; then sTargetDisk="${sDiskDev}"; fi										# A voir pour verifier que la valeur saisie est cohérente	
fi
sTargetChrootDisk="${sTargetDisk}"								# echo "sTargetChrootDisk=\"/dev/sda\"" >> $sChrootVarFile
echo "installation sur ${sTargetDisk}"
if [[ ${bDebugParts} = true ]]; then read -rp "${sDebugPrompt}"; fi

# touch $sChrootVarFile
# echo "#!/usr/bin/env bash" > $sChrootVarFile

# vérification si BIOS ou UEFI
if [[ -d /sys/firmware/efi ]]; then							# automatisation pour les variables bBios & bUefi
	bUefi=true
	read -rp "Installer malgré tout une partition bios boot dans le schéma de partionnement GPT (o/N)" -n 1 biosBootGpt
	if [[ "${biosBootGpt^^}" = "O" ]]; then 	bBios=true
												iBiosBootNr=1
												sTargetGrubType=${sTargetGrubLegacy}
	else 										bBios=false
												iBiosBootNr=0
												sTargetGrubType=${sTargetGrubEfi}
	fi
	iEfiBootNr=$((iBiosBootNr + 1))						# 1 ou 2
	iBootNr=$((iEfiBootNr + 1))							# 2 ou 3 
else 											bUefi=false
												bBios=true
												iBiosBootNr=1
												iEfiBootNr=0
												iBootNr=$((iBiosBootNr + 1))							# 2
												sTargetGrubType=${sTargetGrubLegacy}
fi
 
if [[ ! "${iBootNr}" = "0" ]] && [[ ! "${iBootNr}" = "" ]]; then iRootNr=$((iBootNr + 1)); fi	# 3 ou 4
if [[ ! "${iRootNr}" = "0" ]] && [[ ! "${iRootNr}" = "" ]]; then iHomeNr=$((iRootNr + 1)); fi	# 4 ou 5
if [[ ! "${iHomeNr}" = "0" ]] && [[ ! "${iHomeNr}" = "" ]]; then iSwapNr=$((iHomeNr + 1)); fi	# 5 ou 6 # read -rp "${iBiosBootNr} ${iEfiBootNr} ${iBootNr} ${iRootNr} ${iHomeNr} ${iSwapNr} "

# ***** début de la partie personnalisable *****
# echo nomInterface="" >> $sChrootVarFile
# sBiosBootSize=+2MiB										# ne pas modifier cette variable
sEfiSize=+512MiB											# voir si possible de calculer ces valeurs en fonction de l'espace disque dispo
sBootSize=+512MiB	# +2048MiB								# pour quelques fichiers ISO
sRootSize=+8GiB	# +25GiB									# voir pour calculer l'espace ${sTargetDisk}
sHomeSize=+6GiB	# +20GiB
sSwapSize=+512MiB	# +4096MiB

# utilisateurs à ajouter en sudo
noms_utilisateur='paul gwen malala'							# séparer les noms par des espaces
groupesAccesSysteme=root,users,sys							# optionnels log, systemd-journal, wheel
groupesAccesMateriels=audio,lp,scanner,storage,video		# optionnels video, floppy, optical # ne pas utiliser disk
chrootNomsUsers="${noms_utilisateur}"			 			# echo chrootNomsUsers=\"${noms_utilisateur}\" >> $sChrootVarFile
chrootSysGroup=${groupesAccesSysteme}						# echo chrootSysGroup=${groupesAccesSysteme} >> $sChrootVarFile
chrootHardGroup=${groupesAccesMateriels}				 	# echo chrootHardGroup=${groupesAccesMateriels} >> $sChrootVarFile

# ****** fin de la partie personnalisable ******

makeNewParts() {
	# sTargetDiskSize=$(blockdev --getsize64 "${sTargetDisk}")			# blockdev --getsz /dev/sda # 500118192

	# echo -e "exemple "
	# sTable=$(parted -s "${sTargetDisk}") # cfdisk
	# foundGPT=$(grep -i gpt "$sTable")
	# foundMsDos=$(grep -i msdos "$sTable")
	# if [[ ! "$foundGPT" = "" ]]; then			# isGPT=true					# privilégier GPT à MBR
												# isMBR=false
	# elif [[ ! "$foundMsDos" = "" ]]; then 	# isGPT=false
												# isMBR=true
	# elif [[ "$foundGPT" = "" ] && [[ "$foundMsDos" = "" ]]; then
												# isGPT=true
												# isMBR=false
	# fi

	echo -e "exemple cfdisk ${sTargetDisk} \n ou \n gfdisk ${sTargetDisk} \n pour installer sur:\n${iBiosBootNr}	(biosboot) \n${iEfiBootNr}	/boot/efi \n${iBootNr}	${sBootTarget}\n${iRootNr}	${sRootTarget}\n${iHomeNr}	${sHomeTarget}\n${iSwapNr}	swap\n"
	read -rp "appuyer sur entree pour continuer la création des FileSystem indiqués ou CTRL + C pour annuler avant réécriture de la table des partitions"

	if [[ ! "${iBiosBootNr}" = "0" ]]; then # parted ${sTargetDisk} unit s print free
											# sgdisk --new=0:34:2047 ${sTargetDisk}
											sgdisk -o --new "${iBiosBootNr}::${sBiosBootSize}" --typecode="${iBiosBootNr}:${sBiosBootType}" --change-name="${iBiosBootNr}:'BIOS_boot'" "${sTargetDisk}"
											if [[ ${bBios} = true ]]; then parted "${sTargetDisk}" set "${iBiosBootNr}" bios_grub on; fi # a remettre plus tard
											sBiosBootPart="${sTargetDisk}${iBiosBootNr}"						# 1 iBiosOrEfiNr
											echo "creation du secteur pour bios boot (non activé) sur ${sTargetDisk}${iBiosBootNr}"
	fi
	if [[ ${bDebugParts} = true ]]; then 	read -rp "${sDebugPrompt}"; fi
	if [[ ! "${iEfiBootNr}" = "0" ]]; then 	sgdisk "${sTargetDisk}" -n "${iEfiBootNr}::${sEfiSize}" -t "${iEfiBootNr}":${sEfiPartType} -c ${iEfiBootNr}:'EFI_boot' "${sTargetDisk}"
											sEfiBootPart="${sTargetDisk}${iEfiBootNr}"						# 2 ou 0
											mkfs.fat -F 32 "${sEfiBootPart}"
											echo "creation de la partition /boot/efi terminée sur ${sTargetDisk}${sEfiBootPart}"
	fi
	if [[ ${bDebugParts} = true ]]; then 	read -rp "${sDebugPrompt}"; fi
	# sgdisk -n "${iEfiBootNr}::${sEfiSize}" -t "${iEfiBootNr}:${sEfiPartType}" -c "${iEfiBootNr}":'efi' ${sTargetDisk}
	if [[ ! "${iBootNr}" = "0" ]]; then 	sgdisk -n "${iBootNr}::${sBootSize}" -t "${iBootNr}:${sBootPartType}" -c "${iBootNr}":'boot' "${sTargetDisk}"
											sBootPart="${sTargetDisk}${iBootNr}"							# 3 ou 2
											mkfs.ext4 "${sBootPart}"
											echo "creation de la partition /boot terminée sur ${sTargetDisk} sur partition ${sBootPart}"
	fi
	if [[ ${bDebugParts} = true ]]; then 	read -rp "${sDebugPrompt}"; fi
	if [[ ! "${iRootNr}" = "0" ]]; then 	sgdisk -n "${iRootNr}::${sRootSize}" -t "${iRootNr}:${sRootPartType}" -c "${iRootNr}":'root' "${sTargetDisk}"
											sRootPart="${sTargetDisk}${iRootNr}"							# 4 ou 3
											mkfs.ext4 "${sRootPart}"
											echo "creation de la partition root / terminée sur ${sTargetDisk} sur partition ${sRootPart}"
	fi
	if [[ ${bDebugParts} = true ]]; then 	read -rp "${sDebugPrompt}"; fi
	if [[ ! "${iHomeNr}" = "0" ]]; then 	sgdisk -n "${iHomeNr}::${sHomeSize}" -t "${iHomeNr}:${sHomePartType}" -c "${iHomeNr}":'home' "${sTargetDisk}"
											sHomePart="${sTargetDisk}${iHomeNr}"							# 5 ou 4
											mkfs.ext4 "${sHomePart}"
											echo "creation de la partition /home terminée sur ${sTargetDisk} sur partition ${sHomePart}"
	fi
	if [[ ${bDebugParts} = true ]]; then 	read -rp "${sDebugPrompt}"; fi
	if [[ ! "${iSwapNr}" = "0" ]]; then 	sgdisk -n "${iSwapNr}::${sSwapSize}" -t "${iSwapNr}:${sSwapPartType}" -c "${iSwapNr}":'swap' "${sTargetDisk}"
											sSwapPart="${sTargetDisk}${iSwapNr}"							# 6 ou 5
											mkswap "${sSwapPart}"
											swapon "${sSwapPart}"
											echo "creation de la partition swap terminée sur ${sTargetDisk} sur partition ${sSwapPart}"
	fi
	fdisk -l
	read -rp "Continuer l'installation (CTRL + C pour quitter)" 
}
mountNewParts() { 	# montage des partitions voulues et création des dossiers grub 
	if [[ ${bDebugMount} = true ]]; then 	read -rp "${sDebugPrompt}"; fi
	mount "${sRootPart}" "${sMntChrootTarget}"
	cd "${sMntChrootTarget}" || exit
	if [[ ! "${sBootPart}" = "" ]]; then 	mkdir -p "${sMntChrootTarget}${sBootTarget}" && mount "${sBootPart}" "${sMntChrootTarget}${sBootTarget}"; fi
	if [[ ${bDebugMount} = true ]]; then 	read -rp "${sDebugPrompt}"; fi
	if [[ ! "${sEfiBootPart}" = "" ]]; then mkdir -p "${sMntChrootTarget}${sEfiTarget}" && mount "${sEfiBootPart}" "${sMntChrootTarget}${sEfiTarget}"; fi
	if [[ ${bDebugMount} = true ]]; then 	read -rp "${sDebugPrompt}"; fi
	if [[ ! "${sHomePart}" = "" ]]; then 	mkdir -p "${sMntChrootTarget}${sHomeTarget}" && mount "${sHomePart}" "${sMntChrootTarget}${sHomeTarget}"; fi
}
localeBasicsSetup() {
	# localectl list-keymaps								# liste des agencements clavier dispo
	loadkeys fr-pc											# pour en choisir un
	timedatectl
	timedatectl set-ntp true								# pour régler l'heure
	mkdir -p "${sMntChrootTarget}/grub.d"
	echo "# Clavier fr
insmod keylayouts
keymap fr" > "${sMntChrootTarget}/grub.d/40_custom"
	mkdir -p "${sMntChrootTarget}${sBootTarget}/grub/layouts"
	mkdir -p "${sMntChrootTarget}${sHomeRootTarget}"
}
pacmanMirrorsSetup() {
	ip address show 											# systemctl stop dhcpcd.service
	# connexion au réseau et recherches des mirroirs
	if [[ "${bDebugBaseSetup}" = "true" ]]; then read -rp "${sDebugPrompt}"; fi
	# dhcpcd
	# pacman -Syyuu --noconfirm # ne pas remettre
	pacstrap "${sMntChrootTarget}" pacman-contrib
	pacstrap "${sMntChrootTarget}" pacman-mirrorlist
	sMirrorListFile=/etc/pacman.d/mirrorlist
	sMirrorListBckp="${sMirrorListFile}.backup"
	if [[ -f "${sMirrorListBckp}" ]]; then 		cp "${sMirrorListBckp}" "${sMirrorListFile}"; fi
	cp "${sMirrorListFile}" "${sMirrorListBckp}"
	uncomment "Server" "${sMirrorListFile}" # sed -s 's/^#Server/Server/' "${sMirrorListFile}" # .backup

	cp "${sMirrorListFile}" "${sMntChrootTarget}${sMirrorListFile}"
	# rankmirrors -n 10 "${sMirrorListBckp}" > "${sMirrorListFile}" # rankmirrors supprimé suite erreur à vérifier
}
kernelSetup() {
	if [[ "${bDebugPkgbase}" = "true" ]]; then  read -rp "${sDebugPrompt}"; fi
	# choix des kernels à installer
	sLinuxPkg=$(whiptail --title "Installer le(s) noyau(x) à installer" --checklist \
"Choose preferred Linux distros" 15 60 4 \
linux linux-latest ON \
linux-lts linux-lts ON \
linux-zen linux-zen OFF 3>&1 1>&2 2>&3)
	exitstatus=$?

	#linuxPkg=$(sed 's/\"//g' <<< $(echo "${sLinuxPkg}") )
	#linuxPkg=$(sed "s/\'//g" <<< $(echo "$LinuxPkg") )
	sLinuxPkg=${sLinuxPkg//\"/}; sLinuxPkg=${sLinuxPkg//\'/}

	if [[ ${exitstatus} = 0 ]]; then 			echo -e "Your selected kernels are:\n${sLinuxPkg}"
	else										echo "You choose Cancel."
												exit
	fi

	if [[ "${bDebugPkgbase}" = "true" ]]; then  read -rp "${sDebugPrompt}"; fi # pacman -Syyuu --noconfirm											# normalement pas nécessaire à ce stade du script où les paquets proviennent de l'iso
	# arch-chroot "${sMntChrootTarget}" pacman -S base "${sLinuxPkg}" linux-firmware grub bash dhcpcd nano vim grep arch-chroot man-db man-pages texinfo pacman mkinitcpio # pacstrap "${sMntChrootTarget}" <package1 package2>
	pacstrap "${sMntChrootTarget}" base "${sLinuxPkg}" linux-firmware grub bash zsh dhcpcd nano vim grep man-db man-pages texinfo pacman # mkinitcpio
	pacstrap "${sMntChrootTarget}" arch-chroot
	if [[ ${bDebugBootSetup} = true ]]; then 	read -rp "${sDebugPrompt}"; fi

}
bootMgrSetup() {
	echo -e "bios: ${bBios}\n uefi: ${bUefi}"
	if [[ "${bUefi}" = "true" ]]; then 			read -rp "installation de efibootmgr"
												pacstrap "${sMntChrootTarget}" efibootmgr
	fi
	if [[ ${bDebugBootSetup} = true ]]; then 	read -rp "${sDebugPrompt}"; fi
	if [[ ! "${iBiosBootNr}" = "0" ]]; then 	pacstrap "${sMntChrootTarget}" parted
												parted "${sTargetDisk}" unit s print free
												# sgdisk --new=0:34:2047 ${sTargetDisk}
												parted "${sTargetDisk}" set ${iBiosBootNr} bios_grub on
	fi
	# 1. bootloader
	echo "configuration de grub: grub-install --target=${sTargetGrubType} ${sTargetChrootDisk}"
	# arch-chroot "${sMntChrootTarget}" pacman -Syyuu --noconfirm grub
	if [[ ${bDebugParts} = true ]]; then 		read -rp "UEFI: ${bUefi}"; fi
	if [[ "${bUefi}" = "true" ]]; then 			echo "${bUefi}, installation de efibootmgr"
												arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed efibootmgr
	else
		 										if false; then
													# https://wiki.archlinux.org/title/Partitioning#Tricking_old_BIOS_into_booting_from_GPT
													printf '\200\0\0\0\0\0\0\0\0\0\0\0\001\0\0\0' | dd of="sTargetChrootDisk" bs=1 seek=462
													# https://wiki.archlinux.org/title/Partitioning#Troubleshooting
												fi
	fi
	arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed dosfstools ntfs-3g exfat-utils
	arch-chroot "${sMntChrootTarget}" grub-install --target="${sTargetGrubType}" "${sTargetChrootDisk}"
	arch-chroot "${sMntChrootTarget}" grub-mkconfig -o /boot/grub/grub.cfg # update-grub
	# pour plus d'informations sur grub et le partitionnement
	# https://wiki.archlinux.org/title/Partitioning#GUID_Partition_Table
	# https://wiki.archlinux.org/title/GRUB#Master_Boot_Record_(MBR)_specific_instructions
	# https://wiki.archlinux.org/title/GRUB#Troubleshooting

}
# cp $sChrootVarFile ${sMntChrootTarget}$sChrootVarFile
# if [[ -d "${sMntChrootTarget}" ]]; then 
# 	echo "dossier "${sMntChrootTarget}" trouvé"
# else
# 	echo "dossier "${sMntChrootTarget}" non trouvé"	
# fi
baseUtilsSetup() {
	# 1. installation de quelques utilitaires de base precieux
	if [[ -d "${sMntChrootTarget}" ]]; then
		for sPkg in {bash-completion,zsh-completion,arch-chroot,mkinitcpio,base-devel,git,lsb-release,tmux}; do # tilix,neofetch
			arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed "${sPkg}" || true
		done
		#mkinitcpio -p ${sLinuxPkg}" # linux et/ou linux-lts et/ou linux-zen 
	fi
}
# echo "arch-chroot "${sMntChrootTarget}" dhcpcd"
# arch-chroot "${sMntChrootTarget}" /bin/bash
usersSetup() {
	echo "root:root" | arch-chroot "${sMntChrootTarget}" chpasswd # echo root | passwd root --stdin # passwd # arch-chroot "${sMntChrootTarget}" echo "root:root" | chpasswd # echo root | passwd root --stdin # passwd
	# 2. Création utilisateurs : https://wiki.archlinux.fr/Utilisateurs_et_Groupes # voir pour affiner les groupes
	# groups ${nom_utilisateur}
	# useradd -m -G $groupe1,$groupe2 ${nom_utilisateur}
	# Pour ajouter un utilisateur à un groupe existant (sans conserver les anciens groupes auxquels appartient l'utilisateur) : 
	# usermod -G $groupe1,$groupe2,$groupeN ${nom_utilisateur}
	# Pour ajouter un utilisateur à un groupe existant (en conservant les groupes actuels auxquels appartient l'utilisateur) :
	# usermod -aG $groupe1,$groupe2,$groupeN ${nom_utilisateur}
	# pour créer un groupe
	# groupadd $groupe_utilisateurs
	# Ajouter un utilisateur au groupe:
	# gpasswd -a ${nom_utilisateur} $groupe_utilisateurs

	# A verifier la portée des variables après le chroot, normalement OK?
	# chrootSysGroup=root,users,wheel,sys 		#optionnels log, systemd-journal
	# chrootHardGroup=audio,lp,scanner,storage,video 	# optionnels video, floppy, optical # ne pas utiliser disk
	# chrootNomsUsers='gwen malala'
	sudoersFile="/etc/sudoers"
	sudoersDir="${sudoersFile}.d"
	mkdir -p "${sMntChrootTarget}${sudoersDir}"								# au cas ou on crée le dossier /etc/sudoers.d
	# voir si besoin de decommenter la ligne source ou includedir dans le fichier /etc/sudoers
	uncomment "includedir ${sudoersDir}" "${sudoersFile}"
	uncomment "@includedir ${sudoersDir}" "${sudoersFile}"
	for nom_utilisateur in ${chrootNomsUsers};
	do
		echo "création de l'utilisateur ${nom_utilisateur} (le password sera identique au nom utilisateur)"
		arch-chroot "${sMntChrootTarget}" useradd -mU -G ${chrootSysGroup},${chrootHardGroup} "${nom_utilisateur}"
		echo "${nom_utilisateur}:${nom_utilisateur}" | arch-chroot "${sMntChrootTarget}" chpasswd # echo ${nom_utilisateur} | passwd ${nom_utilisateur} --stdin # passwd ${nom_utilisateur}
		# ajout de l'user au groupe sudoers en créaant un fichier par $user dans /etc/sudoers.d/ # selon exemple du fichier /etc/sudoers root ALL=(ALL) ALL # pas de . ni de ~ dans le nom du fchier
		read -rp "faire de l'user ${nom_utilisateur} un utilisateur sudoer (1 caractère max) : o/N" -n 1 sudoUser	
		if [[ "${sudoUser^^}" = "O" ]]; then
			echo "${nom_utilisateur} ALL=(ALL) ALL" > "${sMntChrootTarget}/etc/sudoers.d/${nom_utilisateur}"
		fi
	done

}
fontsSetup() {
	# polices de caractères
	echo "installation des polices graphiques"
	arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed xorg-fonts-type1 ttf-dejavu font-bh-ttf gsfonts sdl_ttf ttf-bitstream-vera ttf-liberation ttf-freefont ttf-arphic-uming ttf-baekmuk # Polices pour sites multilingue
}
storageSetup() {
	echo "configuration des disques de stockage"
	#arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed ntfs-3g exfat-utils dosfstools
	#arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed
	genfstab -U -p "${sMntChrootTarget}" >> "${sMntChrootTarget}/etc/fstab"
}
networkSetup() { # 2. confifuration réseau via # connection via dhcp
	echo "configuration réseau"
	arch-chroot "${sMntChrootTarget}" /usr/bin/dhcpcd
	arch-chroot "${sMntChrootTarget}" hostnamectl set-hostname archtest			# echo archtest > /etc/hostname # ou sinon # hostnamectl set-hostname archtest
	echo '127.0.0.1 localhost
::1 localhost
127.0.1.1 archtest.localdomain archtest' > ${sMntChrootTarget}/etc/hosts
	arch-chroot "${sMntChrootTarget}" ip link show
	arch-chroot "${sMntChrootTarget}" dhcpcd # "$nomInterface"
	arch-chroot "${sMntChrootTarget}" pacman -Syyuu --noconfirm --needed netctl openssh dhclient
	arch-chroot "${sMntChrootTarget}" systemctl enable dhcpcd sshd # NetworkManager.service
}
graphicServer() { # 3. "config serveurs affichage et clavier" : Xorg voir https://wiki.archlinux.fr/Xorg || wayland https://wiki.archlinux.fr/Wayland
	# arch-chroot "${sMntChrootTarget}" setxkbmap fr
	arch-chroot "${sMntChrootTarget}" pacman -Syu --noconfirm --needed xorg wayland xorg-xwayland 		# pour environnement Xorg complet (contient xorg-apps et xorg-server), pour retro compatibilité avec les applications ne supportant pas wayland
	# arch-chroot "${sMntChrootTarget}" pacman -S --needed xorg-xinit xorg-twm xorg-xclock xterm		# pour environnement Xorg minimaliste

}
gpuSetup() {
	echo "config des pilotes graphiques"																								# pour le matériel graphique
	arch-chroot "${sMntChrootTarget}" pacman -sS --needed xf86-video 																	# affiche liste pilotes libres disponibles
	sGpu=$(lspci | grep -i -e vga -e 3d)
	bNVidia=$(echo "${sGpu}" | grep -i -e nvidia)
	if [[ ! "${bNVidia}" = "" ]]; then 	arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed xf86-video-nouveau ; fi		# pilote libre NVvidia
	bIntel=$(echo "${sGpu}" | grep -i -e intel)
	if [[ ! "${bIntel}" = "" ]]; then 	arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed extra/xf86-video-intel; fi 	# pilote libre Intel
	bVesa=$(echo "${sGpu}" | grep -i -e vesa)
	if [[ ! "${bVesa}" = "" ]]; then 	arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed extra/xf86-video-vesa; fi 	# pilote libre Vesa
	bAMD=$(echo "${sGpu}" | grep -i -e amd)
	if [[ ! "${bAMD}" = "" ]]; then 	arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed extra/xf86-video-amdgpu; fi # pilote libre AMD
}
desktopEnvSetup() {
	echo "desktop environment setup"
	echo -e "choix du/des desktop environment\n0 -> xfce\n1 -> cinnamon\n2 -> gnome\n3 -> deepin\n4 -> budgie\n5 -> enlightenment\n6 -> mate\n7 -> kde\n8 -> lxde\n9 -> lxqt\n10 -> sugar (5-12 children)"
	echo -e "\n ou simple window manager\n11 -> openbox\n12 -> fluxbox\n13 -> i3-wm \n14 -> bspwm"
	read -rp "votre choix? (séparer par des espaces si plusieurs, vide si aucun)" deToInstall
	for de in ${deToInstall}
	do
		if [[ "${de}" = "0" ]]; then 		# 3.0. xfce
			sDePkgs=xfce4 xfce4-goodies
			sLmSvcs=lightdm; sLmPkgs=lightdm lightdm-gtk-greeter;
		elif [[ "${de}" = "1" ]]; then		# 3.1. cinnamon
			sDePkgs=cinnamon nemo-fileroller
			sLmSvcs=gdm; sLmPkgs=gdm;
		elif [[ "${de}" = "2" ]]; then		# 3.2. gnome
			sDePkgs=gnome gnome-chrome-shell # gnome-extra
			sLmSvcs=gdm; sLmPkgs=gdm;
		elif [[ "${de}" = "3" ]]; then		# 3.3. deepin
			sDePkgs=deepin # deepin-extra
			sLmSvcs=lightdm; sLmPkgs=lightdm lightdm-gtk-greeter;
		elif [[ "${de}" = "4" ]]; then		# 3.4. budgie
			sDePkgs=budgie-desktop gnome-chrome-shell # gnome-like
			sLmSvcs=gdm; sLmPkgs=gdm;
		elif [[ "${de}" = "5" ]]; then		# 3.5. enlightenment
			sDePkgs=enlightenment
			sLmSvcs=entrance; sLmPkgs=entrance;
		elif [[ "${de}" = "6" ]]; then		# 3.6. mate
			sDePkgs=mate # mate-extra
			sLmSvcs=gdm; sLmPkgs=gdm;
		elif [[ "${de}" = "7" ]]; then		# 3.7. kde
			sDePkgs=plasma-desktop plasma-wayland-session egl-wayland # plasma-meta kde-applications-meta
			sLmSvcs=sddm; sLmPkgs=sddm;
		elif [[ "${de}" = "8" ]]; then		# 3.8. lxde
			sDePkgs=lxde # lxde-common lxsession openbox lxpanel pcmanfm adobe-source-code-pro-fonts # lxde-gtk3 # version 2 lxde
			sLmSvcs=lxdm; sLmPkgs=lxdm # lxdm-gtk3 # lxdm
		elif [[ "${de}" = "9" ]]; then		# 3.9. lxqt
			sDePkgs=lxqt #lxqt-session lxqt-runner lxqt-panel
			sLmSvcs=sddm; sLmPkgs=sddm; 
		elif [[ "${de}" = "10" ]]; then		# 3.10. sugar
			sDePkgs=sugar sugar-fructose
			sLmSvcs=gdm; sLmPkgs=gdm # à confirmer
		 elif [[ "${de}" = "11" ]]; then		# 3.11. openbox
			sDePkgs=openbox feh obconf lxappearance-obconf lxinput lxrandr ttf-dejavu xterm pcmanfm tint2 # AUR: obkey 
			sLmSvcs=sddm; sLmPkgs=sddm # à confirmer
		# elif [[ "${de}" = "12" ]]; then		# 3.12. fluxbox
			# sDePkgs=fluxbox xorg-xinit feh
			# sLmSvcs=sddm; sLmPkgs=sddm # à confirmer
		elif [[ "${de}" = "13" ]]; then		# 3.13. i3wm
			sDePkgs=i3-wm xorg-xinit xterm
			sLmSvcs=sddm; sLmPkgs=sddm # à confirmer
		elif [[ "${de}" = "14" ]]; then		# 3.14. bspwm
			sDePkgs=sway xorg-xinit xterm
			sLmSvcs=sddm; sLmPkgs=sddm # à confirmer
		elif [[ "${de}" = "15" ]]; then		# 3.14. bspwm
			sDePkgs=bspwm xorg-xinit xterm
			sLmSvcs=sddm; sLmPkgs=sddm # à confirmer
		fi
		arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed "${sDePkgs}"
		arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed "${sLmPkgs}"
		arch-chroot "${sMntChrootTarget}" systemctl enable "${sLmSvcs}.service"
	done
}
setupLocale() {
	# 0. changement de la langue par défaut
	if [[ ${bDebugLclSetup} = true ]]; then read -rp "${sDebugPrompt}"; fi
	LangFr="fr_FR.UTF-8"
	# LangEn="en_US.UTF-8"
	arch-chroot "${sMntChrootTarget}" ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
	cp "${sMntChrootTarget}/etc/locale.gen" "${sMntChrootTarget}/etc/locale.gen.backup"
	# sed -i 's/^#fr_FR/fr_FR/g' "${sMntChrootTarget}/etc/locale.gen"	# enveler les # devant les languages souhaités #echo "creation des locales"
	# sed -i 's/^#en_US/en_US/g' "${sMntChrootTarget}/etc/locale.gen"
	uncomment {"fr_FR","en_US"} "${sMntChrootTarget}/etc/locale.gen"
	arch-chroot "${sMntChrootTarget}" locale-gen
	echo "LANG=${LangFr}
LANGUAGE=${LangFr}
LC_ALL=${LangFr}
LC_MESSAGES=${LangFr}" > ${sMntChrootTarget}/etc/locale.conf
	# arch-chroot "${sMntChrootTarget}" /bin/bash -c export LANG="${LangFr}"
	# arch-chroot "${sMntChrootTarget}" /bin/bash -c export LANGUAGE="${LangFr}"
	# arch-chroot "${sMntChrootTarget}" /bin/bash -c export LC_ALL="${LangFr}"
	# arch-chroot "${sMntChrootTarget}" /bin/bash -c export LC_MESSAGES="${LangFr}"
	if [[ ${bDebugLclSetup} = true ]]; then read -rp "${sDebugPrompt}"; fi
	echo KEYMAP=fr > ${sMntChrootTarget}/etc/vconsole.conf

	echo "config clavier fr" 			# pour le clavier fr normalement tous les users
	# arch-chroot "${sMntChrootTarget}" setxkbmap fr # non permanent
	# arch-chroot "${sMntChrootTarget}" grub-kbdcomp -o "${sBootTarget}/grub/layouts/fr.gkb" fr
	arch-chroot "${sMntChrootTarget}" localectl set-keymap fr
	# arch-chroot "${sMntChrootTarget}" localectl set-x11-keymap fr nécessite que systemd soit lancé ce qui n'est pas le cas au moment du setup
	echo "Section \"InputClass\"
	Identifier		\"Keyboard Layout\"
	MatchIsKeyboard	\"yes\"
	Option			\"XkbLayout\"	\"fr\"
	Option			\"XkbVariant\"	\"latin9\" # accès aux caractères spéciaux plus logique avec \"Alt Gr\" (ex : « » avec \"Alt Gr\" w x)
EndSection" > "${sMntChrootTarget}/etc/X11/xorg.conf.d/30-keyboard.conf"
}
postInstall() {
	echo "post install"
	# 4. "installation de quelques utilitaires de base"
	# arch-chroot "${sMntChrootTarget}" pacman -S --noconfirm --needed base-devel git
	# 4 lignes suivantes pas en root
	# git clone https://aur.archlinux.org/trizen.git
	# cd trizen
	# makepkg -si
	# git clone https://aur.archlinux.org/pamac-aur.git
	# cd pamac-aur
	# makepkg -si
	# trizen inxi
}
unmountParts() {
	for part in "${@}"
	do
		if [[ ! "${part}" = "" ]]; then
			umount -R "${part}"
		fi
	done
}
main() {
	if true; then
		echo "debut de l'installation"
		makeNewParts && mountNewParts
		localeBasicsSetup
		pacmanMirrorsSetup
		kernelSetup
		bootMgrSetup
		baseUtilsSetup
		echo "fin de la preinstallation des paquets essentiels, et debut de la sequence chroot sur le dossier ${sMntChrootTarget}, appuyer sur entree pour continuer"
		graphicServer
		usersSetup
		fontsSetup
		storageSetup
		networkSetup
		# 3. environnement de bureau
		gpuSetup
		desktopEnvSetup
		setupLocale
		postInstall
		# echo "fin de l'installation"
		# fin du chroot et redémarrage
		unmountParts "${sBiosBootPart}" "${sEfiBootPart}" "${sBootPart}" "${sHomePart}" "${sRootPart}" "${sMntChrootTarget}"
		# echo "reboot"
		# reboot
	fi
}