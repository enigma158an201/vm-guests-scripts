#!/usr/bin/env bash
# developpé par enigma158an201 le 20/02/2020
# <>
# A bien lire avant d'aller plus loin
# 1. le programme est prévu pour effacer le disque complet et le partitionner (à voir pour sauter cette partie si souhait utulisateur)
# 2. le script va installer de manière minimale arch / lightDM et XFCE par défaut
# 3. la configuration de connexion wifi n'est pas prise en charge
# 4. A n'utiliser qu'à vos risques et périls
#

# constantes
targetGrubLegacy="i386-pc"
targetGrubEfi="x86_64-efi"

myBiosBootSize=+2MiB
biosBootType=ef02
efiPartType=ef00
bootPartType=8300
rootPartType=8300
homePartType=8302
swapPartType=8200

myRootTarget="/"
mntChrootTarget="/mnt"
myBootTarget="/boot"
myHomeTarget="/home"
myHomeRootTarget="/root"
myEfiTarget="${myBootTarget}/efi"

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
# myChrootVarFile=/root/chrootVars
if false; then less install.txt; elinks wiki.archlinux.fr/Installation; fi

# choix du disque cible ou affectation /dev/sda par default
echo -e "indiquer le disque cible:\n!Attention le disque sera intégralement effacé!\n"
read -rp "exemple /dev/sda (valeur par defaut si rien n'est saisi)" mydisk
mydisk=$(echo "${mydisk}" | grep -i -e "/dev/")
if [[ "${mydisk}" = "" ]]; then
	if [[ -e "/dev/sda" ]]; then targetDisk="/dev/sda"; fi
else
	if [[ -e "${mydisk}" ]]; then targetDisk="${mydisk}"; fi										# A voir pour verifier que la valeur saisie est cohérente	
fi
targetChrootDisk="${targetDisk}"								# echo "targetChrootDisk=\"/dev/sda\"" >> $myChrootVarFile
echo "installation sur ${targetDisk}"
if [[ ${bDebugParts} = true ]]; then read -rp "${sDebugPrompt}"; fi

# touch $myChrootVarFile
# echo "#!/usr/bin/env bash" > $myChrootVarFile

# vérification si BIOS ou UEFI
if [[ -d /sys/firmware/efi ]]; then							# automatisation pour les variables isBios & isUefi
	isUefi=true
	read -rp "Installer malgré tout une partition bios boot dans le schéma de partionnement GPT (o/N)" -n 1 biosBootGpt
	if [[ "${biosBootGpt^^}" = "O" ]]; then
		isBios=true
		myBiosBootNr=1
		targetGrubType=${targetGrubLegacy}
	else
		isBios=false
		myBiosBootNr=0
		targetGrubType=${targetGrubEfi}
	fi
	myEfiBootNr=$((myBiosBootNr + 1))						# 1 ou 2
	myBootNr=$((myEfiBootNr + 1))							# 2 ou 3 
else
	isUefi=false
	isBios=true
	myBiosBootNr=1
	myEfiBootNr=0
	myBootNr=$((myBiosBootNr + 1))							# 2
	targetGrubType=${targetGrubLegacy}
fi
 
if [[ ! "${myBootNr}" = "0" ]] && [[ ! "${myBootNr}" = "" ]]; then myRootNr=$((myBootNr + 1)); fi # 3 ou 4
if [[ ! "${myRootNr}" = "0" ]] && [[ ! "${myRootNr}" = "" ]]; then myHomeNr=$((myRootNr + 1)); fi	# 4 ou 5
if [[ ! "${myHomeNr}" = "0" ]] && [[ ! "${myHomeNr}" = "" ]]; then mySwapNr=$((myHomeNr + 1)); fi	# 5 ou 6 # read -rp "${myBiosBootNr} ${myEfiBootNr} ${myBootNr} ${myRootNr} ${myHomeNr} ${mySwapNr} "

# ***** début de la partie personnalisable *****
# echo nomInterface="" >> $myChrootVarFile
# myBiosBootSize=+2MiB										# ne pas modifier cette variable
myEfiSize=+512MiB											# voir si possible de calculer ces valeurs en fonction de l'espace disque dispo
myBootSize=+512MiB	# +2048MiB								# pour quelques fichiers ISO
myRootSize=+8GiB	# +25GiB								# voir pour calculer l'espace ${targetDisk}
myHomeSize=+6GiB	# +20GiB
mySwapSize=+512MiB	# +4096MiB

# utilisateurs à ajouter en sudo
noms_utilisateur='paul gwen malala'								# séparer les noms par des espaces
groupesAccesSysteme=root,users,sys							# optionnels log, systemd-journal, wheel
groupesAccesMateriels=audio,lp,scanner,storage,video		# optionnels video, floppy, optical # ne pas utiliser disk
chrootNomsUsers="${noms_utilisateur}"				 			# echo chrootNomsUsers=\"${noms_utilisateur}\" >> $myChrootVarFile
chrootSysGroup=${groupesAccesSysteme}							# echo chrootSysGroup=${groupesAccesSysteme} >> $myChrootVarFile
chrootHardGroup=${groupesAccesMateriels}					 	# echo chrootHardGroup=${groupesAccesMateriels} >> $myChrootVarFile

# ****** fin de la partie personnalisable ******

# targetDiskSize=$(blockdev --getsize64 "${targetDisk}")			# blockdev --getsz /dev/sda # 500118192

echo -e "exemple "
# myTable=$(parted -s "${targetDisk}") # cfdisk
# foundGPT=$(grep -i gpt "$myTable")
# foundMsDos=$(grep -i msdos "$myTable")
# if [[ ! "$foundGPT" = "" ]]; then								# privilégier GPT à MBR
	# isGPT=true
	# isMBR=false
# elif [[ ! "$foundMsDos" = "" ]]; then
	# isGPT=false
	# isMBR=true
# elif [[ "$foundGPT" = "" ] && [[ "$foundMsDos" = "" ]]; then
	# isGPT=true
	# isMBR=false
# fi

echo -e "exemple cfdisk ${targetDisk} \n ou \n gfdisk ${targetDisk} \n pour installer sur:\n${myBiosBootNr}	(biosboot) \n${myEfiBootNr}	/boot/efi \n${myBootNr}	${myBootTarget}\n${myRootNr}	${myRootTarget}\n${myHomeNr}	${myHomeTarget}\n${mySwapNr}	swap\n"
read -rp "appuyer sur entree pour continuer la création des FileSystem indiqués ou CTRL + C pour annuler avant réécriture de la table des partitions"

if [[ ! "${myBiosBootNr}" = "0" ]]; then
	# parted ${targetDisk} unit s print free
	# sgdisk --new=0:34:2047 ${targetDisk}
	sgdisk -o --new "${myBiosBootNr}::${myBiosBootSize}" --typecode="${myBiosBootNr}:${biosBootType}" --change-name="${myBiosBootNr}:'BIOS_boot'" "${targetDisk}"
	if [[ ${isBios} = true ]]; then parted "${targetDisk}" set "${myBiosBootNr}" bios_grub on; fi # a remettre plus tard
	myBiosBootPart="${targetDisk}${myBiosBootNr}"						# 1 myBiosOrEfiNr
	echo "creation du secteur pour bios boot (non activé) sur ${targetDisk}${myBiosBootNr}"
fi
if [[ ${bDebugParts} = true ]]; then read -rp "${sDebugPrompt}"; fi
if [[ ! "${myEfiBootNr}" = "0" ]]; then
	sgdisk "${targetDisk}" -n "${myEfiBootNr}::${myEfiSize}" -t "${myEfiBootNr}":${efiPartType} -c ${myEfiBootNr}:'EFI_boot' "${targetDisk}"
	myEfiBootPart="${targetDisk}${myEfiBootNr}"						# 2 ou 0
	mkfs.fat -F 32 "${myEfiBootPart}"
	echo "creation de la partition /boot/efi terminée sur ${targetDisk}${myEfiBootPart}"
fi
if [[ ${bDebugParts} = true ]]; then read -rp "${sDebugPrompt}"; fi
# sgdisk -n "${myEfiBootNr}::${myEfiSize}" -t "${myEfiBootNr}:${efiPartType}" -c "${myEfiBootNr}":'efi' ${targetDisk}
if [[ ! "${myBootNr}" = "0" ]]; then
	sgdisk -n "${myBootNr}::${myBootSize}" -t "${myBootNr}:${bootPartType}" -c "${myBootNr}":'boot' "${targetDisk}"
	myBootPart="${targetDisk}${myBootNr}"							# 3 ou 2
	mkfs.ext4 "${myBootPart}"
	echo "creation de la partition /boot terminée sur ${targetDisk} sur partition ${myBootPart}"
fi
if [[ ${bDebugParts} = true ]]; then read -rp "${sDebugPrompt}"; fi
if [[ ! "${myRootNr}" = "0" ]]; then
	sgdisk -n "${myRootNr}::${myRootSize}" -t "${myRootNr}:${rootPartType}" -c "${myRootNr}":'root' "${targetDisk}"
	myRootPart="${targetDisk}${myRootNr}"							# 4 ou 3
	mkfs.ext4 "${myRootPart}"
	echo "creation de la partition root / terminée sur ${targetDisk} sur partition ${myRootPart}"
fi
if [[ ${bDebugParts} = true ]]; then read -rp "${sDebugPrompt}"; fi
if [[ ! "${myHomeNr}" = "0" ]]; then
	sgdisk -n "${myHomeNr}::${myHomeSize}" -t "${myHomeNr}:${homePartType}" -c "${myHomeNr}":'home' "${targetDisk}"
	myHomePart="${targetDisk}${myHomeNr}"							# 5 ou 4
	mkfs.ext4 "${myHomePart}"
	echo "creation de la partition /home terminée sur ${targetDisk} sur partition ${myHomePart}"
fi
if [[ ${bDebugParts} = true ]]; then read -rp "${sDebugPrompt}"; fi
if [[ ! "${mySwapNr}" = "0" ]]; then
	sgdisk -n "${mySwapNr}::${mySwapSize}" -t "${mySwapNr}:${swapPartType}" -c "${mySwapNr}":'swap' "${targetDisk}"
	mySwapPart="${targetDisk}${mySwapNr}"							# 6 ou 5
	mkswap "${mySwapPart}"
	swapon "${mySwapPart}"
	echo "creation de la partition swap terminée sur ${targetDisk} sur partition ${mySwapPart}"
fi
fdisk -l
read -rp "Continuer l'installation (CTRL + C pour quitter)" 

# localectl list-keymaps								# liste des agencements clavier dispo
loadkeys fr-pc											# pour en choisir un

ip address show 										# systemctl stop dhcpcd.service
timedatectl
timedatectl set-ntp true								# pour régler l'heure

# montage des partitions voulues et création des dossiers grub 
if [[ ${bDebugMount} = true ]]; then read -rp "${sDebugPrompt}"; fi
mount "${myRootPart}" "${mntChrootTarget}"
cd "${mntChrootTarget}" || exit
if [[ ! "${myBootPart}" = "" ]]; then
	mkdir -p "${mntChrootTarget}${myBootTarget}" && mount "${myBootPart}" "${mntChrootTarget}${myBootTarget}"
fi
if [[ ${bDebugMount} = true ]]; then read -rp "${sDebugPrompt}"; fi
if [[ ! "${myEfiBootPart}" = "" ]]; then
	mkdir -p "${mntChrootTarget}${myEfiTarget}" && mount "${myEfiBootPart}" "${mntChrootTarget}${myEfiTarget}"
fi
if [[ ${bDebugMount} = true ]]; then read -rp "${sDebugPrompt}"; fi
if [[ ! "${myHomePart}" = "" ]]; then
	mkdir -p "${mntChrootTarget}${myHomeTarget}" && mount "${myHomePart}" "${mntChrootTarget}${myHomeTarget}"
fi

mkdir -p "${mntChrootTarget}/grub.d"
echo "# Clavier fr
insmod keylayouts
keymap fr" > "${mntChrootTarget}/grub.d/40_custom"
mkdir -p "${mntChrootTarget}${myBootTarget}/grub/layouts"
mkdir -p "${mntChrootTarget}${myHomeRootTarget}"

# connexion au réseau et recherches des mirroirs
if [[ "${bDebugBaseSetup}" = "true" ]]; then read -rp "${sDebugPrompt}"; fi
# dhcpcd
# pacman -Syyuu --noconfirm # ne pas remettre
pacstrap "${mntChrootTarget}" pacman-contrib
pacstrap "${mntChrootTarget}" pacman-mirrorlist
mirrorlistFile=/etc/pacman.d/mirrorlist
mirrorlistBckp="${mirrorlistFile}.backup"
if [[ -f "${mirrorlistBckp}" ]]; then cp "${mirrorlistBckp}" "${mirrorlistFile}"; fi
cp "${mirrorlistFile}" "${mirrorlistBckp}"
uncomment "Server" "${mirrorlistFile}" # sed -s 's/^#Server/Server/' "${mirrorlistFile}" # .backup

cp "${mirrorlistFile}" "${mntChrootTarget}${mirrorlistFile}"
# rankmirrors -n 10 "${mirrorlistBckp}" > "${mirrorlistFile}" # rankmirrors supprimé suite erreur à vérifier

if [[ "${bDebugPkgbase}" = "true" ]]; then  read -rp "${sDebugPrompt}"; fi
# choix des kernels à installer
sLinuxPkg=$(whiptail --title "Installer le(s) noyau(x) à installer" --checklist \
"Choose preferred Linux distros" 15 60 4 \
linux linux-latest ON \
linux-lts linux-lts ON \
linux-zen linux-zen OFF 3>&1 1>&2 2>&3)

#linuxPkg=$(sed 's/\"//g' <<< $(echo "${sLinuxPkg}") )
#linuxPkg=$(sed "s/\'//g" <<< $(echo "$LinuxPkg") )
sLinuxPkg=${sLinuxPkg//\"/}; sLinuxPkg=${sLinuxPkg//\'/}

exitstatus=$?
if [[ ${exitstatus} = 0 ]]; then
	echo -e "Your selected kernels are:\n${sLinuxPkg}"
else
	echo "You choose Cancel."
	exit
fi

if [[ "${bDebugPkgbase}" = "true" ]]; then  read -rp "${sDebugPrompt}"; fi # pacman -Syyuu --noconfirm											# normalement pas nécessaire à ce stade du script où les paquets proviennent de l'iso
# arch-chroot "${mntChrootTarget}" pacman -S base "${sLinuxPkg}" linux-firmware grub bash dhcpcd nano vim grep arch-chroot man-db man-pages texinfo pacman mkinitcpio # pacstrap "${mntChrootTarget}" <package1 package2>
pacstrap "${mntChrootTarget}" base "${sLinuxPkg}" linux-firmware grub bash zsh dhcpcd nano vim grep man-db man-pages texinfo pacman # mkinitcpio
pacstrap "${mntChrootTarget}" arch-chroot
if [[ ${bDebugBootSetup} = true ]]; then read -rp "${sDebugPrompt}"; fi
echo -e "bios: ${isBios}\n uefi: ${isUefi}"
if [[ "${isUefi}" = "true" ]]; then
	read -rp "installation de efibootmgr"
	pacstrap "${mntChrootTarget}" efibootmgr
fi
if [[ ${bDebugBootSetup} = true ]]; then read -rp "${sDebugPrompt}"; fi
if [[ ! "${myBiosBootNr}" = "0" ]]; then
	pacstrap "${mntChrootTarget}" parted
	parted "${targetDisk}" unit s print free
	# sgdisk --new=0:34:2047 ${targetDisk}
	parted "${targetDisk}" set ${myBiosBootNr} bios_grub on
fi
echo "fin de la preinstallation des paquets essentiels, et debut de la sequence chroot sur le dossier ${mntChrootTarget}, appuyer sur entree pour continuer"
# cp $myChrootVarFile ${mntChrootTarget}$myChrootVarFile
# if [[ -d "${mntChrootTarget}" ]]; then 
# 	echo "dossier "${mntChrootTarget}" trouvé"
# else
# 	echo "dossier "${mntChrootTarget}" non trouvé"	
# fi

if [[ -d "${mntChrootTarget}" ]]; then
	# echo "arch-chroot "${mntChrootTarget}" dhcpcd"
	# arch-chroot "${mntChrootTarget}" /bin/bash
	arch-chroot "${mntChrootTarget}" /usr/bin/dhcpcd
	arch-chroot "${mntChrootTarget}" hostnamectl set-hostname archtest			# echo archtest > /etc/hostname # ou sinon # hostnamectl set-hostname archtest
	echo '127.0.0.1 localhost
::1 localhost
127.0.1.1 archtest.localdomain archtest' > ${mntChrootTarget}/etc/hosts

	# 0. changement de la langue par défaut
	if [[ ${bDebugLclSetup} = true ]]; then read -rp "${sDebugPrompt}"; fi
	LangFr="fr_FR.UTF-8"
	# LangEn="en_US.UTF-8"
	arch-chroot "${mntChrootTarget}" ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
	cp "${mntChrootTarget}/etc/locale.gen" "${mntChrootTarget}/etc/locale.gen.backup"
	# sed -i 's/^#fr_FR/fr_FR/g' "${mntChrootTarget}/etc/locale.gen"	# enveler les # devant les languages souhaités #echo "creation des locales"
	# sed -i 's/^#en_US/en_US/g' "${mntChrootTarget}/etc/locale.gen"
	uncomment {"fr_FR","en_US"} "${mntChrootTarget}/etc/locale.gen"
	arch-chroot "${mntChrootTarget}" locale-gen
	echo "LANG=${LangFr}
LANGUAGE=${LangFr}
LC_ALL=${LangFr}
LC_MESSAGES=${LangFr}" > ${mntChrootTarget}/etc/locale.conf
	# arch-chroot "${mntChrootTarget}" /bin/bash -c export LANG="${LangFr}"
	# arch-chroot "${mntChrootTarget}" /bin/bash -c export LANGUAGE="${LangFr}"
	# arch-chroot "${mntChrootTarget}" /bin/bash -c export LC_ALL="${LangFr}"
	# arch-chroot "${mntChrootTarget}" /bin/bash -c export LC_MESSAGES="${LangFr}"
	if [[ ${bDebugLclSetup} = true ]]; then read -rp "${sDebugPrompt}"; fi
	echo KEYMAP=fr > ${mntChrootTarget}/etc/vconsole.conf
	echo "root:root" | arch-chroot "${mntChrootTarget}" chpasswd # echo root | passwd root --stdin # passwd # arch-chroot "${mntChrootTarget}" echo "root:root" | chpasswd # echo root | passwd root --stdin # passwd

	# 1. bootloader
	echo "configuration de grub: grub-install --target=${targetGrubType} ${targetChrootDisk}"
	# arch-chroot "${mntChrootTarget}" pacman -Syyuu --noconfirm grub
	if [[ ${bDebugParts} = true ]]; then read -rp "UEFI: ${isUefi}"; fi
	if [[ "${isUefi}" = "true" ]]; then
		echo "${isUefi}, installation de efibootmgr"
		arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed efibootmgr
	else
		if false; then
			# https://wiki.archlinux.org/title/Partitioning#Tricking_old_BIOS_into_booting_from_GPT
			printf '\200\0\0\0\0\0\0\0\0\0\0\0\001\0\0\0' | dd of="targetChrootDisk" bs=1 seek=462
			# https://wiki.archlinux.org/title/Partitioning#Troubleshooting
		fi
	fi
	arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed dosfstools ntfs-3g exfat-utils
	arch-chroot "${mntChrootTarget}" grub-install --target="${targetGrubType}" "${targetChrootDisk}"
	arch-chroot "${mntChrootTarget}" grub-mkconfig -o /boot/grub/grub.cfg # update-grub
	# pour plus d'informations sur grub et le partitionnement
	# https://wiki.archlinux.org/title/Partitioning#GUID_Partition_Table
	# https://wiki.archlinux.org/title/GRUB#Master_Boot_Record_(MBR)_specific_instructions
	# https://wiki.archlinux.org/title/GRUB#Troubleshooting

	# ajout de quelques utilitaires precieux de base
	arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed {bash,zsh}-completion
	# arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed zsh-completion
	arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed arch-chroot
	arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed neofetch
	arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed base-devel # base-dev
	arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed git
	arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed lsb-release

	# *********** postInstall *******************
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
	mkdir -p "${mntChrootTarget}${sudoersDir}"								# au cas ou on crée le dossier /etc/sudoers.d
	# voir si besoin de decommenter la ligne source ou includedir dans le fichier /etc/sudoers
	uncomment "includedir ${sudoersDir}" "${sudoersFile}"
	uncomment "@includedir ${sudoersDir}" "${sudoersFile}"
	for nom_utilisateur in ${chrootNomsUsers};
	do
		echo "création de l'utilisateur ${nom_utilisateur} (le password sera identique au nom utilisateur)"
		arch-chroot "${mntChrootTarget}" useradd -mU -G ${chrootSysGroup},${chrootHardGroup} "${nom_utilisateur}"
		echo "${nom_utilisateur}:${nom_utilisateur}" | arch-chroot "${mntChrootTarget}" chpasswd # echo ${nom_utilisateur} | passwd ${nom_utilisateur} --stdin # passwd ${nom_utilisateur}
		# ajout de l'user au groupe sudoers en créaant un fichier par $user dans /etc/sudoers.d/ # selon exemple du fichier /etc/sudoers root ALL=(ALL) ALL # pas de . ni de ~ dans le nom du fchier
		read -rp "faire de l'user ${nom_utilisateur} un utilisateur sudoer (1 caractère max) : o/N" -n 1 sudoUser	
		if [[ "${sudoUser^^}" = "O" ]]; then
			echo "${nom_utilisateur} ALL=(ALL) ALL" > "${mntChrootTarget}/etc/sudoers.d/${nom_utilisateur}"
		fi
	done

	# 3. "config serveurs affichage et clavier" 														# Xorg voir https://wiki.archlinux.fr/Xorg # wayland https://wiki.archlinux.fr/Wayland
	# arch-chroot "${mntChrootTarget}" setxkbmap fr
	arch-chroot "${mntChrootTarget}" pacman -Syu --noconfirm --needed xorg wayland xorg-xwayland 		# pour environnement Xorg complet (contient xorg-apps et xorg-server), pour retro compatibilité avec les applications ne supportant pas wayland
	## arch-chroot "${mntChrootTarget}" pacman -S --needed xorg-xinit xorg-twm xorg-xclock xterm		# pour environnement Xorg minimaliste
	arch-chroot "${mntChrootTarget}" pacman -Syu --noconfirm --needed tmux # | tilix
	# polices de caractères
	echo "installation des polices graphiques"
	arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed xorg-fonts-type1 ttf-dejavu font-bh-ttf gsfonts sdl_ttf ttf-bitstream-vera ttf-liberation ttf-freefont ttf-arphic-uming ttf-baekmuk # Polices pour sites multilingue

	# 2. confifuration réseau via # connection via dhcp
	arch-chroot "${mntChrootTarget}" ip link show
	arch-chroot "${mntChrootTarget}" dhcpcd # "$nomInterface"
	arch-chroot "${mntChrootTarget}" pacman -Syyuu --noconfirm --needed netctl openssh dhclient
	arch-chroot "${mntChrootTarget}" systemctl enable dhcpcd sshd # NetworkManager.service

	# 3. environnement de bureau
	echo "config des pilotes graphiques"												# pour le matériel graphique
	arch-chroot "${mntChrootTarget}" pacman -sS --needed xf86-video 									# affiche liste pilotes libres disponibles
	retourGPU=$(lspci | grep -i -e vga -e 3d)

	isNVidia=$(echo "${retourGPU}" | grep -i -e nvidia)
	if [[ ! "${isNVidia}" = "" ]]; then
		arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed xf86-video-nouveau 		# pilote libre NVvidia
	fi
	isIntel=$(echo "${retourGPU}" | grep -i -e intel)
	if [[ ! "${isIntel}" = "" ]]; then
		arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed extra/xf86-video-intel 	# pilote libre Intel
	fi
	isVesa=$(echo "${retourGPU}" | grep -i -e vesa)
	if [[ ! "${isVesa}" = "" ]]; then
		arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed extra/xf86-video-vesa 	# pilote libre Vesa
	fi
	isAMD=$(echo "${retourGPU}" | grep -i -e amd)
	if [[ ! "${isAMD}" = "" ]]; then
		arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed extra/xf86-video-amdgpu 	# pilote libre AMD
	fi
	echo -e "choix du/des desktop environment\n0 -> xfce\n1 -> cinnamon\n2 -> gnome\n3 -> deepin\n4 -> budgie\n5 -> enlightenment\n6 -> mate\n7 -> kde\n8 -> lxde\n9 -> lxqt\n10 -> sugar (5-12 children)"
	echo -e "\n ou simple window manager\n11 -> openbox\n12 -> fluxbox\n13 -> i3-wm \n14 -> bspwm"
	read -rp "votre choix? (séparer par des espaces si plusieurs, vide si aucun)" deToInstall
	for de in ${deToInstall}
	do
		if [[ "${de}" = "0" ]]; then 		# 3.0. xfce
			myDePkgNames=xfce4 xfce4-goodies
			myLmSvcName=lightdm; myLmPkgName=lightdm lightdm-gtk-greeter;
		elif [[ "${de}" = "1" ]]; then		# 3.1. cinnamon
			myDePkgNames=cinnamon nemo-fileroller
			myLmSvcName=gdm; myLmPkgName=gdm;
		elif [[ "${de}" = "2" ]]; then		# 3.2. gnome
			myDePkgNames=gnome gnome-chrome-shell # gnome-extra
			myLmSvcName=gdm; myLmPkgName=gdm;
		elif [[ "${de}" = "3" ]]; then		# 3.3. deepin
			myDePkgNames=deepin # deepin-extra
			myLmSvcName=lightdm; myLmPkgName=lightdm lightdm-gtk-greeter;
		elif [[ "${de}" = "4" ]]; then		# 3.4. budgie
			myDePkgNames=budgie-desktop gnome-chrome-shell # gnome-like
			myLmSvcName=gdm; myLmPkgName=gdm;
		elif [[ "${de}" = "5" ]]; then		# 3.5. enlightenment
			myDePkgNames=enlightenment
			myLmSvcName=entrance; myLmPkgName=entrance;
		elif [[ "${de}" = "6" ]]; then		# 3.6. mate
			myDePkgNames=mate # mate-extra
			myLmSvcName=gdm; myLmPkgName=gdm;
		elif [[ "${de}" = "7" ]]; then		# 3.7. kde
			myDePkgNames=plasma-desktop plasma-wayland-session egl-wayland # plasma-meta kde-applications-meta
			myLmSvcName=sddm; myLmPkgName=sddm;
		elif [[ "${de}" = "8" ]]; then		# 3.8. lxde
			myDePkgNames=lxde # lxde-common lxsession openbox lxpanel pcmanfm adobe-source-code-pro-fonts # lxde-gtk3 # version 2 lxde
			myLmSvcName=lxdm; myLmPkgName=lxdm # lxdm-gtk3 # lxdm
		elif [[ "${de}" = "9" ]]; then		# 3.9. lxqt
			myDePkgNames=lxqt #lxqt-session lxqt-runner lxqt-panel
			myLmSvcName=sddm; myLmPkgName=sddm; 
		elif [[ "${de}" = "10" ]]; then		# 3.10. sugar
			myDePkgNames=sugar sugar-fructose
			myLmSvcName=gdm; myLmPkgName=gdm # à confirmer
		 elif [[ "${de}" = "11" ]]; then		# 3.11. openbox
			myDePkgNames=openbox feh obconf lxappearance-obconf lxinput lxrandr ttf-dejavu xterm pcmanfm tint2 # AUR: obkey 
			myLmSvcName=sddm; myLmPkgName=sddm # à confirmer
		# elif [[ "${de}" = "12" ]]; then		# 3.12. fluxbox
			# myDePkgNames=fluxbox xorg-xinit feh
			# myLmSvcName=sddm; myLmPkgName=sddm # à confirmer
		elif [[ "${de}" = "13" ]]; then		# 3.13. i3wm
			myDePkgNames=i3-wm xorg-xinit xterm
			myLmSvcName=sddm; myLmPkgName=sddm # à confirmer
		elif [[ "${de}" = "14" ]]; then		# 3.14. bspwm
			myDePkgNames=sway xorg-xinit xterm
			myLmSvcName=sddm; myLmPkgName=sddm # à confirmer
		elif [[ "${de}" = "15" ]]; then		# 3.14. bspwm
			myDePkgNames=bspwm xorg-xinit xterm
			myLmSvcName=sddm; myLmPkgName=sddm # à confirmer
		fi
		arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed "${myDePkgNames}"
		arch-chroot "${mntChrootTarget}" pacman -S --noconfirm --needed "${myLmPkgName}"
		arch-chroot "${mntChrootTarget}" systemctl enable "${myLmSvcName}.service"
	done

	echo "config clavier fr" 			# pour le clavier fr normalement tous les users
	# arch-chroot "${mntChrootTarget}" setxkbmap fr # non permanent
	# arch-chroot "${mntChrootTarget}" grub-kbdcomp -o "${myBootTarget}/grub/layouts/fr.gkb" fr
	arch-chroot "${mntChrootTarget}" localectl set-keymap fr
	# arch-chroot "${mntChrootTarget}" localectl set-x11-keymap fr nécessite que systemd soit lancé ce qui n'est pas le cas au moment du setup
	echo "Section \"InputClass\"
	Identifier		\"Keyboard Layout\"
	MatchIsKeyboard	\"yes\"
	Option			\"XkbLayout\"	\"fr\"
	Option			\"XkbVariant\"	\"latin9\" # accès aux caractères spéciaux plus logique avec \"Alt Gr\" (ex : « » avec \"Alt Gr\" w x)
EndSection" > "${mntChrootTarget}/etc/X11/xorg.conf.d/30-keyboard.conf"

	genfstab -U -p "${mntChrootTarget}" >> "${mntChrootTarget}/etc/fstab"
	# arch-chroot "${mntChrootTarget}" "pacman -S --noconfirm --needed mkinitcpio; mkinitcpio -p ${sLinuxPkg}" # linux et/ou linux-lts et/ou linux-zen 

	# a bouger en post install
	# pacman -Sy --noconfirm --needed base-devel git
	# 4 lignes suivantes pas en root
	# git clone https://aur.archlinux.org/trizen.git
	# cd trizen
	# makepkg -si
	# git clone https://aur.archlinux.org/pamac-aur.git
	# cd pamac-aur
	# makepkg -si
	# trizen inxi
	umount -R "${myBiosBootPart}"
	umount -R "${myEfiBootPart}"
	umount -R "${myBootPart}"
	umount -R "${myHomePart}"
	umount -R "${myRootPart}"
	umount -R "${mntChrootTarget}"														# fin du chroot et redémarrage
fi
# reboot
