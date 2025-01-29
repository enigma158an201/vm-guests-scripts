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
myEfiTarget="$myBootTarget/efi"

# fin des constantes

fdisk -l													# pour identifier le disque
# voir pour obtenir une double confirmation de l'user avant de continuer confirmUser1 et confirmUser2
# myChrootVarFile=/root/chrootVars
if false; then less install.txt; elinks wiki.archlinux.fr/Installation; fi

echo -e "indiquer le disque cible:\n!Attention le disque sera intégralement effacé!\n"
read -rp "exemple /dev/sda (valeur par defaut si rien n'est saisi)" mydisk
mydisk=$(echo "$mydisk" | grep -i -e "/dev/")
if [ "$mydisk" = "" ]; then # [ -f $mydisk ] &&
	targetDisk="/dev/sda"
else
	if [ -f "$mydisk" ]; then targetDisk="$mydisk"; fi										# A voir pour verifier que la valeur saisie est cohérente	
fi

# touch $myChrootVarFile
# echo "#!/usr/bin/env bash" > $myChrootVarFile
targetChrootDisk="$targetDisk"								# echo "targetChrootDisk=\"/dev/sda\"" >> $myChrootVarFile
echo "installation sur $targetDisk"

if [ -d /sys/firmware/efi ]; then							# automatisation pour les variables isBios & isUefi
	isUefi=true
	read -rp "Installer malgré tout une partition bios boot dans le schéma de partionnement GPT (o/N)" -n 1 biosBootGpt
	if [ "${biosBootGpt^^}" = "O" ]; then
		isBios=true
		myBiosBootNr=1
		targetGrub=$targetGrubLegacy
	else
		isBios=false
		myBiosBootNr=0
		targetGrub=$targetGrubEfi
	fi
	myEfiBootNr=$((myBiosBootNr + 1))						# 1 ou 2
	myBootNr=$((myEfiBootNr + 1))							# 2 ou 3 
else
	isUefi=false
	isBios=true
	myBiosBootNr=1
	myEfiBootNr=0
	myBootNr=$((myBiosBootNr + 1))							# 2
	targetGrub=$targetGrubLegacy
fi

myRootNr=$((myBootNr + 1))									# 3 ou 4
myHomeNr=$((myRootNr + 1))									# 4 ou 5
mySwapNr=$((myHomeNr + 1))									# 5 ou 6 # read -rp "$myBiosBootNr $myEfiBootNr $myBootNr $myRootNr $myHomeNr $mySwapNr "

# ***** début de la partie personnalisable *****
# echo nomInterface="" >> $myChrootVarFile
# myBiosBootSize=+2MiB										# ne pas modifier cette variable
myEfiSize=+512MiB											# voir si possible de calculer ces valeurs en fonction de l'espace disque dispo
myBootSize=+512MiB # +2048MiB								# pour quelques fichiers ISO
myRootSize=+8GiB   # +25GiB									# voir pour calculer l'espace $targetDisk
myHomeSize=+6GiB   # +20GiB
mySwapSize=+512MiB # +4096MiB

# utilisateurs à ajouter en sudo
noms_utilisateur='paul gwen malala'								# séparer les noms par des espaces
groupesAccesSysteme=root,users,sys							# optionnels log, systemd-journal, wheel
groupesAccesMateriels=audio,lp,scanner,storage,video		# optionnels video, floppy, optical # ne pas utiliser disk
chrootNomsUsers="$noms_utilisateur"				 			# echo chrootNomsUsers=\"$noms_utilisateur\" >> $myChrootVarFile
chrootSysGroup=$groupesAccesSysteme							# echo chrootSysGroup=$groupesAccesSysteme >> $myChrootVarFile
chrootHardGroup=$groupesAccesMateriels					 	# echo chrootHardGroup=$groupesAccesMateriels >> $myChrootVarFile

# ****** fin de la partie personnalisable ******

# targetDiskSize=$(blockdev --getsize64 "$targetDisk")			# blockdev --getsz /dev/sda # 500118192

echo -e "exemple cfdisk $targetDisk \n ou \n gdisk $targetDisk"
# myTable=$(parted -s "$targetDisk") # cfdisk
# foundGPT=$(grep -i gpt "$myTable")
# foundMsDos=$(grep -i msdos "$myTable")
# if [ ! "$foundGPT" = "" ]; then								# privilégier GPT à MBR
	# isGPT=true
	# isMBR=false
# elif [ ! "$foundMsDos" = ""  ]; then
	# isGPT=false
    # isMBR=true
# elif [ "$foundGPT" = "" ] && [ "$foundMsDos" = ""  ]; then
	# isGPT=true
	# isMBR=false
# fi

echo -e "exemple pour installer sur:\n$myBiosBootNr	(biosboot) \n$myEfiBootNr	/boot/efi \n$myBootNr	$myBootTarget\n$myRootNr	$myRootTarget\n$myHomeNr	$myHomeTarget\n$mySwapNr	swap\n"
read -rp "appuyer sur entree pour continuer la création des FileSystem indiqués"

if [ ! "$myBiosBootNr" = "0" ]; then
	# parted $targetDisk unit s print free
	# sgdisk --new=0:34:2047 $targetDisk
	sgdisk -o --new $myBiosBootNr::$myBiosBootSize --typecode=$myBiosBootNr:$biosBootType --change-name=$myBiosBootNr:'BIOS_boot' "$targetDisk"
	# parted $targetDisk set $myBiosBootNr bios_grub on # a remettre plus tard
	# myBiosBootPart=$targetDisk$myBiosBootNr						# 1 myBiosOrEfiNr
	echo "creation du secteur pour bios boot (non activé) sur $targetDisk$myBiosBootNr"
fi

if [ ! "$myEfiBootNr" = "0" ]; then
	sgdisk "$targetDisk" -n "$myEfiBootNr::$myEfiSize" -t "$myEfiBootNr":$efiPartType -c $myEfiBootNr:'EFI_boot' "$targetDisk"
	myEfiBootPart="$targetDisk$myEfiBootNr"						# 2 ou 0
	mkfs.fat -F 32 "$myEfiBootPart"
	echo "creation de la partition /boot/efi terminée sur $targetDisk$myEfiBootPart"
fi
# sgdisk -n "$myEfiBootNr::$myEfiSize" -t "$myEfiBootNr:$efiPartType" -c "$myEfiBootNr":'efi' $targetDisk
if [ ! "$myBootNr" = "0" ]; then
	sgdisk -n "$myBootNr::$myBootSize" -t "$myBootNr:$bootPartType" -c "$myBootNr":'boot' "$targetDisk"
	myBootPart="$targetDisk$myBootNr"							# 3 ou 2
	mkfs.ext4 "$myBootPart"
	echo "creation de la partition /boot terminée sur $targetDisk sur partition $myBootPart"
fi
if [ ! "$myRootNr" = "0" ]; then
	sgdisk -n "$myRootNr::$myRootSize" -t "$myRootNr:$rootPartType" -c "$myRootNr":'root' "$targetDisk"
	myRootPart="$targetDisk$myRootNr"							# 4 ou 3
	mkfs.ext4 "$myRootPart"
	echo "creation de la partition root / terminée sur $targetDisk sur partition $myRootPart"
fi
if [ ! "$myHomeNr" = "0" ]; then
	sgdisk -n "$myHomeNr::$myHomeSize" -t "$myHomeNr:$homePartType" -c "$myHomeNr":'home' "$targetDisk"
	myHomePart="$targetDisk$myHomeNr"							# 5 ou 4
	mkfs.ext4 "$myHomePart"
	echo "creation de la partition /home terminée sur $targetDisk sur partition $myHomePart"
fi
if [ ! "$mySwapNr" = "0" ]; then
	sgdisk -n "$mySwapNr::$mySwapSize" -t "$mySwapNr:$swapPartType" -c "$mySwapNr":'swap' "$targetDisk"
	mySwapPart="$targetDisk$mySwapNr"							# 6 ou 5
	mkswap "$mySwapPart"
	swapon "$mySwapPart"
	echo "creation de la partition swap terminée sur $targetDisk sur partition $mySwapPart"
fi

fdisk -l
read -rp "Continuer l'installation (CTRL + C pour quitter)" 

# localectl list-keymaps  								# liste des agencements clavier dispo
loadkeys fr-pc											# pour en choisir un

ip address show 								        # systemctl stop dhcpcd.service
timedatectl
timedatectl set-ntp true								# pour régler l'heure

mount "$myRootPart" "$mntChrootTarget"
cd "$mntChrootTarget" || exit
if [ ! "$myBootPart" = "" ]; then
	mkdir -p "$mntChrootTarget$myBootTarget" && mount "$myBootPart" "$mntChrootTarget$myBootTarget"
fi
if [ ! "$myEfiBootPart" = "" ]; then
	mkdir -p "$mntChrootTarget$myEfiTarget" && mount "$myEfiBootPart" "$mntChrootTarget$myEfiTarget"
fi
if [ ! "$myHomePart" = "" ]; then
	mkdir -p "$mntChrootTarget$myHomeTarget" && mount "$myHomePart" "$mntChrootTarget$myHomeTarget"
fi
mkdir -p "$mntChrootTarget$myBootTarget/grub"
mkdir -p "$mntChrootTarget$myHomeRootTarget"

dhcpcd
pacman -Syyuu --noconfirm
pacstrap $mntChrootTarget pacman-contrib
pacstrap $mntChrootTarget pacman-mirrorlist
mirrorlistFile=/etc/pacman.d/mirrorlist
mirrorlistBckp="$mirrorlistFile.backup"

if [ -f "$mirrorlistBckp" ]; then cp "$mirrorlistBckp" "$mirrorlistFile"; fi
cp "$mirrorlistFile" "$mirrorlistBckp"
sed -s 's/^#Server/Server/' "$mirrorlistFile" # .backup
cp "$mirrorlistFile" "$mntChrootTarget$mirrorlistFile"

# rankmirrors -n 10 "$mirrorlistBckp" > "$mirrorlistFile" # rankmirrors supprimé suite erreur à vérifier
linuxPkg=$(whiptail --title "Installer le(s) noyau(x) à installer" --checklist \
"Choose preferred Linux distros" 15 60 4 \
"linux" "linux-latest" ON \
"linux-lts" "linux-lts" ON \
"linux-zen" "linux-zen" OFF 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your favorite distros are:" $linuxPkg
else
    echo "You chose Cancel."
fi

pacman -Syyuu --noconfirm											# normalement pas nécessaire à ce stade du script où les paquets proviennent de l'iso
arch-chroot $mntChrootTarget pacman -S base "$linuxPkg" linux-firmware grub bash dhcpcd nano vim grep arch-chroot man-db man-pages texinfo pacman mkinitcpio # pacstrap $mntChrootTarget <package1 package2>

echo -e "bios: $isBios\n uefi: $isUefi"
if [ "$isUefi" = "true" ]; then
	read -rp "installation de efibootmgr"
	pacstrap $mntChrootTarget efibootmgr
fi

if [ ! "$myBiosBootNr" = "0" ]; then
	pacstrap $mntChrootTarget parted
	parted "$targetDisk" unit s print free
	# sgdisk --new=0:34:2047 $targetDisk
	parted "$targetDisk" set $myBiosBootNr bios_grub on
fi

echo "fin de la preinstallation des paquets essentiels, et debut de la sequence chroot sur le dossier $mntChrootTarget, appuyer sur entree pour continuer"
# cp $myChrootVarFile $mntChrootTarget$myChrootVarFile
# if [ -d $mntChrootTarget ]; then 
# 	echo "dossier $mntChrootTarget trouvé"
# else
# 	echo "dossier $mntChrootTarget non trouvé"	
# fi
if [ -d $mntChrootTarget ]; then 
echo "arch-chroot $mntChrootTarget dhcpcd"
# arch-chroot $mntChrootTarget /bin/bash
arch-chroot $mntChrootTarget /usr/bin/dhcpcd

arch-chroot $mntChrootTarget hostnamectl set-hostname archtest			# echo archtest > /etc/hostname # ou sinon # hostnamectl set-hostname archtest
arch-chroot $mntChrootTarget echo '127.0.0.1 localhost' > $mntChrootTarget/etc/hosts
arch-chroot $mntChrootTarget echo '::1 localhost' >> $mntChrootTarget/etc/hosts
arch-chroot $mntChrootTarget echo '127.0.1.1 archtest.localdomain archtest' >> $mntChrootTarget/etc/hosts

# 0. changement de la langue par défaut
LangFr="fr_FR.UTF-8"
arch-chroot $mntChrootTarget ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
arch-chroot $mntChrootTarget cp /etc/locale.gen /etc/locale.gen.backup
arch-chroot $mntChrootTarget sed -i 's/^#fr_FR/fr_FR/' /etc/locale.gen	# enveler les # devant les languages souhaités #echo "creation des locales"
arch-chroot $mntChrootTarget locale-gen
arch-chroot $mntChrootTarget echo "$LangFr
LANGUAGE=$LangFr
LC_ALL=LangFr" > $mntChrootTarget/etc/locale.conf
arch-chroot $mntChrootTarget export LANG=$LangFr
arch-chroot $mntChrootTarget export LANGUAGE=$LangFr
arch-chroot $mntChrootTarget export LC_ALL=$LangFr

arch-chroot $mntChrootTarget echo KEYMAP=fr > $mntChrootTarget/etc/vconsole.conf
arch-chroot $mntChrootTarget mkinitcpio -p "$linuxPkg" # linux et/ou linux-lts et/ou linux-zen 
echo "root:root" | arch-chroot $mntChrootTarget chpasswd # echo root | passwd root --stdin # passwd # arch-chroot $mntChrootTarget echo "root:root" | chpasswd # echo root | passwd root --stdin # passwd

# 1. bootloader
echo "configuration de grub: grub-install --target=$targetGrub $targetChrootDisk"
# arch-chroot $mntChrootTarget pacman -Syyuu --noconfirm grub
read -rp "UEFI: $isUefi"
if [ "$isUefi" = "true" ]; then
	echo "$isUefi, installation de efibootmgr"
	arch-chroot "$mntChrootTarget" pacman -S --noconfirm efibootmgr
else
	if false; then
	# https://wiki.archlinux.org/title/Partitioning#Tricking_old_BIOS_into_booting_from_GPT
	printf '\200\0\0\0\0\0\0\0\0\0\0\0\001\0\0\0' | dd of="targetChrootDisk" bs=1 seek=462
	# https://wiki.archlinux.org/title/Partitioning#Troubleshooting
	fi
fi
arch-chroot "$mntChrootTarget" pacman -S --noconfirm dosfstools ntfs-3g exfat-utils
arch-chroot "$mntChrootTarget" grub-install --target=$targetGrub "$targetChrootDisk"
arch-chroot "$mntChrootTarget" grub-mkconfig -o /boot/grub/grub.cfg # update-grub
# pour plus d'informations sur grub et le partitionnement
# https://wiki.archlinux.org/title/Partitioning#GUID_Partition_Table
# https://wiki.archlinux.org/title/GRUB#Master_Boot_Record_(MBR)_specific_instructions
# https://wiki.archlinux.org/title/GRUB#Troubleshooting

# ajout de quelques utilitaires precieux de base
arch-chroot "$mntChrootTarget" pacman -S --noconfirm bash-completion
arch-chroot "$mntChrootTarget" pacman -S --noconfirm zsh-completion 
arch-chroot "$mntChrootTarget" pacman -S --noconfirm arch-chroot
arch-chroot "$mntChrootTarget" pacman -S --noconfirm neofetch
arch-chroot "$mntChrootTarget" pacman -S --noconfirm base-devel # base-dev
arch-chroot "$mntChrootTarget" pacman -S --noconfirm git
arch-chroot "$mntChrootTarget" pacman -S --noconfirm lsb-release

# *********** postInstall *******************
# 2. Création utilisateurs : https://wiki.archlinux.fr/Utilisateurs_et_Groupes # voir pour affiner les groupes
# groups $nom_utilisateur
# useradd -m -G $groupe1,$groupe2 $nom_utilisateur
# Pour ajouter un utilisateur à un groupe existant (sans conserver les anciens groupes auxquels appartient l'utilisateur) : 
# usermod -G $groupe1,$groupe2,$groupeN $nom_utilisateur
# Pour ajouter un utilisateur à un groupe existant (en conservant les groupes actuels auxquels appartient l'utilisateur) :
# usermod -aG $groupe1,$groupe2,$groupeN $nom_utilisateur
# pour créer un groupe
# groupadd $groupe_utilisateurs
# Ajouter un utilisateur au groupe:
# gpasswd -a $nom_utilisateur $groupe_utilisateurs

# A verifier la portée des variables après le chroot, normalement OK?
# chrootSysGroup=root,users,wheel,sys 		#optionnels log, systemd-journal
# chrootHardGroup=audio,lp,scanner,storage,video 	# optionnels video, floppy, optical # ne pas utiliser disk
# chrootNomsUsers='gwen malala'
arch-chroot "$mntChrootTarget" mkdir -p /etc/sudoers.d								# au cas ou on crée le dossier /etc/sudoers.d
# voir si besoin de decommenter la ligne source ou includedir dans le fichier /etc/sudoers
for nom_utilisateur in $chrootNomsUsers;
do
	echo "création de l'utilisateur $nom_utilisateur (le password sera identique au nom utilisateur)"
    arch-chroot "$mntChrootTarget" useradd -mU -G $chrootSysGroup,$chrootHardGroup "$nom_utilisateur"
    echo "$nom_utilisateur:$nom_utilisateur" | arch-chroot $mntChrootTarget chpasswd # echo $nom_utilisateur | passwd $nom_utilisateur --stdin # passwd $nom_utilisateur
	# ajout de l'user au groupe sudoers en créaant un fichier par $user dans /etc/sudoers.d/ # selon exemple du fichier /etc/sudoers root ALL=(ALL) ALL # pas de . ni de ~ dans le nom du fchier
	read -rp "faire de l'user $nom_utilisateur un utilisateur sudoer (1 caractère max) : o/N" -n 1 sudoUser	
	if [ "${sudoUser^^}" = "O" ]; then
		arch-chroot "$mntChrootTarget" echo "$nom_utilisateur\ ALL\=\(ALL\)\ ALL" > "/etc/sudoers.d/$nom_utilisateur"
	fi
done

# 3. "config serveurs affichage et clavier" 														# Xorg voir https://wiki.archlinux.fr/Xorg # wayland https://wiki.archlinux.fr/Wayland
arch-chroot "$mntChrootTarget" setxkbmap fr
arch-chroot "$mntChrootTarget" pacman -Syu --noconfirm xorg wayland xorg-xwayland		# pour environnement Xorg complet (contient xorg-apps et xorg-server), pour retro compatibilité avec les applications ne supportant pas wayland
## arch-chroot "$mntChrootTarget" pacman -S xorg-xinit xorg-twm xorg-xclock xterm		# pour environnement Xorg minimaliste
# polices de caractères
echo "installation des polices graphiques"
arch-chroot "$mntChrootTarget" pacman -S --noconfirm xorg-fonts-type1 ttf-dejavu font-bh-ttf gsfonts sdl_ttf ttf-bitstream-vera ttf-liberation ttf-freefont ttf-arphic-uming ttf-baekmuk # Polices pour sites multilingue

# 2. confifuration réseau via # connection via dhcp
arch-chroot "$mntChrootTarget" ip link show
arch-chroot "$mntChrootTarget" dhcpcd # "$nomInterface"
arch-chroot "$mntChrootTarget" pacman -Syyuu --noconfirm netctl openssh dhclient
arch-chroot "$mntChrootTarget" systemctl enable dhcpcd sshd # NetworkManager.service

# 3. environnement de bureau
echo -e "choix du/des desktop environment\n0 -> xfce\n1 -> cinnamon\n2 -> gnome\n3 -> deepin\n4 -> budgie\n5 -> enlightenment\n6 -> mate\n7 -> kde\n8 -> lxde\n9 -> lxqt\n10 -> sugar (5-12 children)"
read -rp "votre choix? (séparer par des espaces si plusieurs, vide si aucun)" deToInstall
for de in $deToInstall
do
	if [ "$de" = "0" ]; then 		# 3.0. xfce
		arch-chroot $mntChrootTarget pacman -S --noconfirm xfce4 xfce4-goodies
		arch-chroot $mntChrootTarget pacman -S --noconfirm lightdm lightdm-gtk-greeter
		arch-chroot $mntChrootTarget systemctl enable lightdm.service
	elif [ "$de" = "1" ]; then		# 3.1. cinnamon
		arch-chroot $mntChrootTarget pacman -S --noconfirm cinnamon nemo-fileroller
		arch-chroot $mntChrootTarget pacman -S --noconfirm gdm
		arch-chroot $mntChrootTarget systemctl enable gdm.service
	elif [ "$de" = "2" ]; then		# 3.2. gnome
		arch-chroot $mntChrootTarget pacman -S --noconfirm gnome gnome-chrome-shell # gnome-extra
		arch-chroot $mntChrootTarget pacman -S --noconfirm gdm
		arch-chroot $mntChrootTarget systemctl enable gdm.service
	elif [ "$de" = "3" ]; then		# 3.3. deepin
		arch-chroot $mntChrootTarget pacman -S --noconfirm deepin # deepin-extra
		arch-chroot $mntChrootTarget pacman -S --noconfirm lightdm lightdm-gtk-greeter
		arch-chroot $mntChrootTarget systemctl enable lightdm.service
	elif [ "$de" = "4" ]; then		# 3.4. budgie
		arch-chroot $mntChrootTarget pacman -S --noconfirm budgie-desktop gnome-chrome-shell # gnome-like
		arch-chroot $mntChrootTarget pacman -S --noconfirm gdm
		arch-chroot $mntChrootTarget systemctl enable gdm.service
	elif [ "$de" = "5" ]; then		# 3.5. enlightenment
		arch-chroot $mntChrootTarget pacman -S --noconfirm enlightenment
		arch-chroot $mntChrootTarget pacman -S --noconfirm entrance
		arch-chroot $mntChrootTarget systemctl enable entrance.service
	elif [ "$de" = "6" ]; then		# 3.6. mate
		arch-chroot $mntChrootTarget pacman -S --noconfirm mate # mate-extra
		arch-chroot $mntChrootTarget pacman -S --noconfirm gdm
		arch-chroot $mntChrootTarget systemctl enable gdm.service
	elif [ "$de" = "7" ]; then		# 3.7. kde
		arch-chroot $mntChrootTarget pacman -S --noconfirm plasma-desktop plasma-wayland-session egl-wayland # plasma-meta kde-applications-meta
		arch-chroot $mntChrootTarget pacman -S --noconfirm sddm
		arch-chroot $mntChrootTarget systemctl enable sddm.service
	elif [ "$de" = "8" ]; then		# 3.8. lxde
		arch-chroot $mntChrootTarget pacman -S --noconfirm lxde-common lxsession openbox  # lxde-gtk3 # version 2 lxde
		arch-chroot $mntChrootTarget pacman -S --noconfirm lxdm
		arch-chroot $mntChrootTarget systemctl enable lxdm.service
	elif [ "$de" = "9" ]; then		# 3.9. lxqt
		arch-chroot $mntChrootTarget pacman -S --noconfirm sugar sugar-fructose
		arch-chroot $mntChrootTarget pacman -S --noconfirm sddm
		arch-chroot $mntChrootTarget systemctl enable sddm.service
	elif [ "$de" = "10" ]; then		# 3.10. sugar
		arch-chroot $mntChrootTarget pacman -S --noconfirm sugar sugar-fructose
		arch-chroot $mntChrootTarget pacman -S --noconfirm gdm # à confirmer
		arch-chroot $mntChrootTarget systemctl enable gdm.service
	fi
done

echo "config clavier fr" 			# pour le clavier fr normalement tous les users
arch-chroot "$mntChrootTarget" setxkbmap fr
arch-chroot "$mntChrootTarget" localectl set-keymap fr
arch-chroot "$mntChrootTarget" localectl set-x11-keymap fr

echo "config des pilotes graphiques"												# pour le matériel graphique
arch-chroot "$mntChrootTarget" pacman -sS xf86-video 									# affiche liste pilotes libres disponibles
retourGPU=$(lspci | grep -i -e vga -e 3d)

isNVidia=$(echo "$retourGPU" | grep -i -e nvidia)
if [ ! "$isNVidia" = "" ]; then
	arch-chroot "$mntChrootTarget" pacman -S --noconfirm xf86-video-nouveau 		# pilote libre NVvidia
fi
isIntel=$(echo "$retourGPU" | grep -i -e intel)
if [ ! "$isIntel" = "" ]; then
	arch-chroot "$mntChrootTarget" pacman -S --noconfirm extra/xf86-video-intel 	# pilote libre Intel
fi
isVesa=$(echo "$retourGPU" | grep -i -e vesa)
if [ ! "$isVesa" = "" ]; then
	arch-chroot "$mntChrootTarget" pacman -S --noconfirm extra/xf86-video-vesa 	# pilote libre Vesa
fi
isAMD=$(echo "$retourGPU" | grep -i -e amd)
if [ ! "$isAMD" = "" ]; then
	arch-chroot "$mntChrootTarget" pacman -S --noconfirm extra/xf86-video-amdgpu 	# pilote libre AMD
fi

genfstab -U -p "$mntChrootTarget" >> "$mntChrootTarget/etc/fstab"

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

umount -R "$mntChrootTarget"														# fin du chroot et redémarrage
fi
# reboot
