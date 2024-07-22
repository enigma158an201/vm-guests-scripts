# vm-guests-scripts
## useful scripts for VM guest

These scrips simply intend to upgrade Pkg, remove obsoletes then clean pkg cache, to install them:
 
```
[ cd <the_folder_you_want> ]
git clone https://github.com/enigma158an201/vm-guests-scripts.git
```
then from folder where you cloned this repo (given by ```pwd```)
```
cd vm-guests-scripts
```
to use these scripts, your user must have sudo rights, then
- if your vm is a debian based linux distro like ubuntu mint etc., then
```
./deblike-update.sh
```
- if your vm is a arch linux based linux distro manjaro arco garuda etc., then
```
./archlike-update.sh
```
- if your vm is a bsd based distro like freebsd openbsd etc., then
```
./bsdlike-update.sh
```
- if your vm is a cards based distro nutyx gratos etc., then
```
./nutyxlike-update.sh
```
- if your vm is a void based linux distro, then
```
./void-update.sh
```
