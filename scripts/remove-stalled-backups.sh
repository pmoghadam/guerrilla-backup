#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CWD=$(dirname $(readlink -f $0))
LOG="$CWD/../logs/stall-$(date +%Y%m%d-%H%M%S).log"
BACKUPDIR="$CWD/../backups/"

find $BACKUPDIR -maxdepth 2 -type f -name "backup.lock" | 
	while read LOCKFILE; do
		BACKUP_PID="$(cat $LOCKFILE)"
		EXIST="$(ps -A | grep get-backup.sh | grep $BACKUP_PID)"
		if [ "$EXIST" == "" ]; then
			echo -n "$(date +%F-%T) -- Stall backup found: " | tee -a $LOG
			echo "$(basename $(dirname $LOCKFILE))" | tee -a $LOG
			rm -v $LOCKFILE | tee -a $LOG
		fi
	done

