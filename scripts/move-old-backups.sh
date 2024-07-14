#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CWD=$(dirname $(readlink -f $0))
CONF="$CWD/../guerrilla.conf"
LOGDIR="$CWD/../logs"
LOG="$LOGDIR/move-$(date +%Y%m%d-%H%M%S).log"
TMP=$(mktemp)
BACKUPDIR="$CWD/../backups/"
DELDIR="$CWD/../delete/$(date +%Y%m%d-%H%M%S)"

# Read config file
. $CONF

KEEPDAYS=${KEEPDAYS:-4}

TODAY=$(date +%Y%m%d)
OLDEST=$(( $TODAY - $KEEPDAYS ))

echo "######################################################" | tee -a $LOG
echo "$(date +%F-%T) -- Remove backups older than or equal to: $OLDEST"     | tee -a $LOG

mkdir -p $DELDIR
find $BACKUPDIR -maxdepth 2 -type d  > $TMP
grep -E '[0-9]{8}-[0-9]{6}$' $TMP | while read LINE; do
	LATEST="$(basename $(readlink -f $(dirname $LINE)/latest))"
	CURRENT=$(basename $(readlink -f $LINE))
	D=$(basename $LINE  | sed -e 's,-.*,,')
	if [ "$D" -le "$OLDEST" ]; then
		LOCKFILE="$(dirname $LINE)/backup.lock"
		if [ -e "$LOCKFILE" ]; then
			echo "Lock file found : $LOCKFILE" | tee -a $LOG
			echo "Keep locked: $LINE" | tee -a $LOG
		elif [ "$CURRENT" == "$LATEST" ]; then
			echo "Keep latest: $LINE" | tee -a $LOG
		else
			echo "Remove: $LINE" | tee -a $LOG
			mv $LINE.log $LINE $(mktemp -d -p $DELDIR)
		fi
	fi
done

# Move global log files
ls $LOGDIR/*.log | while read LINE; do
	D=$(echo $LINE | sed -E 's,.*-([0-9]{8})[-\.].*,\1,')
	if [ "$D" -le "$OLDEST" ]; then
		echo "Remove: $LINE" | tee -a $LOG
		mv $LINE $(mktemp -d -p $DELDIR)
	fi
done

echo "$(date +%F-%T) -- End of cleanup script." | tee -a $LOG
echo "######################################################" | tee -a $LOG

[ -e "$TMP" ] && rm $TMP
