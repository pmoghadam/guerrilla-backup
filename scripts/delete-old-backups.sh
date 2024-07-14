#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CWD=$(dirname $(readlink -f $0))
LOCK="$CWD/../logs/delete.lock"
LOG="$CWD/../logs/delete-$(date +%Y%m%d).log"

if [ -e "$LOCK" ]; then
	OLDPID=$(cat $LOCK)
	EXIST=$(ps -A | grep $OLDPID | wc -l)
	if [ "$EXIST" != "0" ]; then
		echo "Lock file found : $LOCK"
		echo "Previous instance is running..."
		exit
	fi
fi
echo $$ > $LOCK

DELBASE="$CWD/../delete"
EMPTYDIR=$(mktemp -d)

echo "$(date +%F-%T) -- Start rsync for delete." | tee -a $LOG
mkdir -p $DELBASE

# --log-file=$LOG
rsync --archive --delete ${EMPTYDIR}/ ${DELBASE}/

rmdir ${EMPTYDIR} ${DELBASE}
echo "$(date +%F-%T) -- End of delete." | tee -a $LOG
[ -e "$LOCK" ] && rm -rf $LOCK
