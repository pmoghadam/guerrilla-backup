#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CWD=$(dirname $(readlink -f $0))
BACKUPDIR="$CWD/../backups/"
find $BACKUPDIR -maxdepth 2 -type f -name "backup.lock" 

