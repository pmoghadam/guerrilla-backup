#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
LIST=$(mktemp)
CWD=$(dirname $(readlink -f $0))
CONF="$CWD/../conf/guerrilla.conf"
LOG="$CWD/../logs/backup-$(date +%Y%m%d-%H%M%S).log"
HOSTSDIR="$CWD/../hosts"
TIMEOUT=60

# Read config file
. $CONF

# Set default values
PARALLEL=${PARALLEL:-4}

# Prepare parallel value
(( PARALLEL*=3 ))

ls $HOSTSDIR > $LIST
N=$(wc -l $LIST | cut -d' ' -f1)
for I in $(seq 1 $N); do
	HNAME=$(sed -n "${I}p" $LIST)
	CONCURRENT=$(ps fax | egrep -c [r]sync)
	while [ "$CONCURRENT" -ge "$PARALLEL" ]; do
		echo "$(( CONCURRENT/3 )) backups are running in parallel, wait ..." | tee -a $LOG
		sleep $TIMEOUT
		CONCURRENT=$(ps fax | egrep -c [r]sync)
	done
	echo "$(date +%F-%T) -- Start backup: $HNAME" | tee -a $LOG
	$CWD/get-backup.sh $HNAME &> /dev/null &
	sleep 5
done

[ -e $LIST ] && rm $LIST
