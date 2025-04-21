#!/usr/bin/env bash

# script by Enigma158an201
# https://www.it-connect.fr/comment-mettre-en-place-mariadb-galera-cluster-sur-debian-11/

set -euo pipefail

#mysql -u root -p

prerequisites() { apt-get update && apt-get install mariadb-server galera-4; }
checkGaleraDbEngine() { #mariadb -u root <<EOF #show variables like 'default_storage_engine'; #EOF
	bInnoDb=$(mariadb -s -r -u root -e "show variables like 'default_storage_engine';" | grep -iq "innodb" && echo "true" || echo "false")
	#shellcheck disable=SC2207
	tDbNames=( $(mariadb -s -r -u root -e "SHOW DATABASES;" | tail -n +2) )
	for sDbName in "${tDbNames[@]}"; do
		sMyISAM=$(mariadb -s -r -u root -e "SELECT TABLE_NAME, ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA = '${sDbName}' and ENGINE = 'myISAM';")
		if [[ -n ${sMyISAM} ]]; then
			bMyISAM="true"
			break
		else
			bMyISAM="false"
		fi
	done
	iErr=0
	if ! ${bInnoDb}; then echo echo -e "\t>>> ERROR: InnoDB is not the default storage engine, please check your configuration."; iErr=$((iErr + 1)); fi
	if ${bMyISAM}; then
		echo -e "\t>>> ERROR: MyISAM tables found in the database, please convert them to InnoDB."
		echo -e "\t>>> ERROR: Please check your configuration and try again."
		iErr=$((iErr + 2))
	fi
	return ${iErr}
}
configMainCluster() { # see /usr/share/mysql/wsrep.cnf
	if [[ ${1} = m ]]; then sUserChoice="master"; elif [[ ${1} = s ]]; then sUserChoice="slave"; else return 1; fi
	if [[ -e /root/bkp/60-galera.conf ]]; then rsync -avzh /etc/mysql/mariadb.conf.d/60-galera.cnf /root/bkp/60-galera.conf; fi
	echo "[galera]
# Mandatory settings
wsrep_on = ON
wsrep_provider = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_name = \"Galera_Cluster_Konnect\"
wsrep_cluster_address = gcomm://${sGaleraNodeIps}
binlog_format = row
default_storage_engine = InnoDB
innodb_autoinc_lock_mode = 2
innodb_force_primary_key = 1

# Allow server to accept connections on all interfaces.
bind-address = 0.0.0.0

# Optional settings
#wsrep_slave_threads = 1
#innodb_flush_log_at_trx_commit = 0
log_error = /var/log/mysql/error-galera.log" | tee /etc/mysql/mariadb.conf.d/60-galera.cnf
	systemctl stop mariadb
	if [[ ${sUserChoice} = "master" ]]; then galera_new_cluster; fi
	systemctl start mariadb
	mariadb -s -r -u root -e "show status like 'wsrep_cluster_size';"
}
installationTypeChoice() {
	echo -e "\t>>> which cluster type to you want? (type m for master galera cluster, s for slave one, any other key to display status)"
	read -rp "(m/S) ?" -n 1 sClusterType
	configMainCluster "${sClusterType,,}"
}
displayGaleraClusterStatus() { # see /usr/share/mysql/wsrep.cnf
	mariadb -s -r -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
	mariadb -s -r -u root -e "SHOW STATUS LIKE 'wsrep_cluster_state_uuid';"
	mariadb -s -r -u root -e "SHOW STATUS LIKE 'wsrep_ready';"
	mariadb -s -r -u root -e "SHOW STATUS LIKE 'wsrep_connected';"
	mariadb -s -r -u root -e "SHOW STATUS LIKE 'wsrep_local_state_comment';"
}
checkMariaRemoteConnection() {
	echo -e "\t>>> Checking remote connection..."
	if [[ $(grep "bind-address" /etc/mysql/mariadb.conf.d/50-server.cnf | grep -v '#') =~ 127.0.0.1 ]]; then
		echo -e "\t>>> ERROR: bind-address is set to localhost, please change it to	0.0.0.0"
	else
		echo -e "\t>>> Galera Cluster setup completed."
	fi
}
dnsTodo() {
	echo -e "\t>>> Please add or check the following lines to your /etc/hosts file:"
	for sIp in $(echo "${sGaleraNodeIps}" | tr ',' ' '); do
		echo -e "\t\t${sIp} $(getent hosts "${sIp}" | awk '{print $2}')"
	done
}
mainSetupGalera() {
	sGaleraNodeIps="192.168.0.100,192.168.0.108" #values separated by commas
	prerequisites
	checkGaleraDbEngine
	installationTypeChoice || true
	displayGaleraClusterStatus
	checkMariaRemoteConnection
	dnsTodo

}
mainSetupGalera