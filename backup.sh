#!/bin/bash

usage () {
  echo 'Benutzung: backup.sh -s "Quellverzeichniss" -d "Zielverzeichniss" -n "Anzahl der Backups"' >&2
  exit 1
}

while getopts ":s:d:n:" opt; do
  case $opt in
    s)
      SOURCE=${OPTARG%/}
      ;;
    d)
      DEST=${OPTARG%/}
      ;;
    n)
      BAKNUM=$OPTARG
      ;;
    \?)
      echo "Ungueltige Option: -$OPTARG" >&2
      usage
      ;;
    :)
      echo "Die Option -$OPTARG erfordert ein zusaetzliches Argument." >&2
      usage
      ;;
  esac
done


REGEX='^[0-9]+$'
if [[ ! -d $SOURCE ]] || [[ ! -d $DEST ]] || [[ ! $BAKNUM =~ $REGEX ]]; then
    usage
fi

NOW=$(date +%Y-%m-%d-%H%M%S)
FOLDERS=$(find $DEST -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort -n)
NEWEST=$(echo "$FOLDERS" | tail -1)
OLDEST=$(echo "$FOLDERS" | head -1)
NUM=$(echo "$FOLDERS" | wc -l)
SOURCESHA1=$(tar -c --mode='777' --mtime='1970-01-01' --owner=0 --group=0 -C "$SOURCE" . | sha1sum | awk '{print $1}')

if [ -e $DEST/$NEWEST.sha1 ]; then
   if [ "$SOURCESHA1" == "$(cat $DEST/$NEWEST.sha1)" ]; then
     echo "Das Quell- und das Zielverzeichniss sind gleich; Beende."
     exit 0
   fi
fi

if [ $NUM -ge $BAKNUM ]; then
   rm -rf $DEST/$OLDEST
   rm -rf $DEST/$OLDEST.sha1
fi

rsync -ahv --delete --link-dest="$DEST/$NEWEST" $SOURCE/ $DEST/$NOW
echo $SOURCESHA1 > $DEST/$NOW.sha1
