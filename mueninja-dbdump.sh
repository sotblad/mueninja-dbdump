#!/bin/bash

DB_user=mmndbdump
DB=mueninja
MAINDIR=./dump
DIR=mueninja-dbdump-$(date +%Y%m%d%H%M%S)
DUMPDIR=$MAINDIR/$DIR
DUMPNAM=$DIR.tar.bz2
FULLDUMPNAM=$MAINDIR/$DUMPNAM
TIMESTAMP=$(date +%s)
DATE=$(date -u)
LINKSFILE=$(head -n 13 links.md)
HEADER=$(cat header.md)

[ -n "$DUMPDIR" ] || DUMPDIR=.
test -d $DUMPDIR || mkdir -p $DUMPDIR

echo "Dumping tables into separate SQL command files for database '$DB' into dir=$DUMPDIR"

tbl_count=0

for t in $(mysql -NBA -u $DB_user -D $DB -e 'show tables') 
do 
    echo "DUMPING TABLE: $DB.$t"
    mysqldump -u $DB_user --lock-tables=false $DB $t > $DUMPDIR/$t.sql
    tbl_count=$(( tbl_count + 1 ))
done

echo "$tbl_count tables dumped from database '$DB' into dir=$DUMPDIR"

echo "Compressing archive $DUMPNAM into $DUMPDIR"

cd $MAINDIR
tar cvjf $DUMPNAM $DIR
cd ..

echo "Calculating checksum of $DIRFIN/$DUMPNAM"

SIZE=$(stat -c%s $FULLDUMPNAM)
#SHA1=$(sha1sum $FULLDUMPNAM | cut -f1 -d' ')
SHA256=$(sha256sum $FULLDUMPNAM | cut -f1 -d' ')

echo "Sending $DIRFIN/$DUMPNAM to transfer.sh"

URL=$(curl --progress-bar --upload-file $FULLDUMPNAM https://transfer.sh/$DUMPNAM)

echo "Cleaning up"
rm $FULLDUMPNAM
cd $MAINDIR
rm -rf $DIR
cd ..

echo "Generating new links.md file and README.md"
echo -e "| [$DATE]($URL) | $SIZE | $SHA256 | \n$LINKSFILE" > links.md
cat header.md links.md > README.md

echo "Auto commit and push"
git add README.md links.md
git commit -m "$DATE - autoupdate"
git push
