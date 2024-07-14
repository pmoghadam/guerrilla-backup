#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CWD=$(dirname $(readlink -f "$0"))
PARENTDIR=$(dirname "$CWD")
BACKUPROOT="$PARENTDIR/backups"
DATETIME="$(date '+%Y%m%d-%H%M%S')"

################################################################################
# cleanup / Ctrl-C handler

function cleanup { 
	[ -e "$BACKUPLOCK" ] && rm -v "$BACKUPLOCK"
	exit
} 
trap cleanup 2

################################################################################


# Check syntax
if [ "$#" != "1" ]; then
	echo "Syntax: $0 [hostname]"
	exit
fi
HNAME="$1"

# Check hostname resolve
IP=$(dig +short $HNAME)
if [ "$IP" == "" ]; then
	echo "$HNAME not resolved to IP address"
	exit
fi

# Read global host defaults
. "$PARENTDIR/conf/defaults.conf"

# Read custom host config
. "$PARENTDIR/hosts/$HNAME"

SRCDIRS="$DIRS $ADDITIONAL_DIRS"
EXCLUDES="$EXCLUDES $ADDITIONAL_EXCLUDES"
BACKUPDIR="$BACKUPROOT/$HNAME/$DATETIME"
BACKUPLOG="$BACKUPDIR.log"
BACKUPLOCK="$BACKUPROOT/$HNAME/backup.lock"
LATESTLINK="$BACKUPROOT/$HNAME/latest"

# Lock mechanism
if [ -e "$BACKUPLOCK" ] ; then
	echo "Previous backup is in progress..."
	echo "Lock file found : $BACKUPLOCK"
	exit
fi
mkdir -vp "$BACKUPDIR"
echo "$$" > "$BACKUPLOCK"

# Run Commands
if [ "$COMMANDS" != "" ]; then
        echo "$COMMANDS" | while read CMD; do
                echo $CMD
                ssh -o StrictHostKeyChecking=no -p$SSHPORT \
                        $SSHUSER@$IP "$CMD" >> "${BACKUPDIR}/commands.txt" 2>&1
        done
fi

# Check if source addresses exist on remote server
SRCFOUND=""
ARR=($SRCDIRS)
N=${#ARR[@]}
((N--))
for I in $(seq 0 $N); do
	SRC="${ARR[$I]}"
	ssh -o StrictHostKeyChecking=no -p$SSHPORT \
		$SSHUSER@$IP "[ -e $SRC ] || [ -s $SRC ]"
	[ "$?" == "0" ] && SRCFOUND="$SRCFOUND $SRC"
done
SRCDIRS="$SRCFOUND"

# Prepare Source addresses
SRCDIRS=$(echo $SRCDIRS | expand | tr -s " " | sed \
	-e 's,/ , ,g' 		\
	-e 's,/$,,' 		\
	-e 's,^/,:/,' 		\
	-e 's, /, :/,g'		\
	-e 's, :,/ :,g' -e 's,$,/,'
)

echo "Source Directories: $SRCDIRS" | tee -a "$BACKUPLOG"

# Prepare exclude addresses
EXCLUDES="$(echo $EXCLUDES)"
[ ! -z "$EXCLUDES" ] && EXCLUDES=$(echo "$EXCLUDES"  | sed -e 's,^,--exclude=,' -e 's, , --exclude=,g')

echo "Exclude directories: $EXCLUDES" | tee -a "$BACKUPLOG"

for SRC in $SRCDIRS; do
	DST=$(echo $SRC | sed -e 's,^:/,,')
	mkdir -vp "${BACKUPDIR}/$DST"
	rsync   --archive --delete --verbose --mkpath               \
		--log-file="$BACKUPLOG"                             \
		--link-dest="$LATESTLINK/$DST"                      \
		--rsh="ssh -o StrictHostKeyChecking=no -p$SSHPORT"  \
		$EXCLUDES $SSHUSER@$IP$SRC "${BACKUPDIR}/$DST"
	echo "rsync return code: $?" | tee -a "$BACKUPLOG"
done

rm -vrf "$LATESTLINK" | tee -a "$BACKUPLOG"
ln -vsfn "$BACKUPDIR" "$LATESTLINK" | tee -a "$BACKUPLOG"
echo "Backup procedure complete: $(date '+%Y%m%d-%H%M%S')"

cleanup

