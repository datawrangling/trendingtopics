#!/bin/sh

# grab directory from S3 to local target directory using s3cmd
#
# example usage:
# bash /mnt/app/current/lib/scripts/S3fetch.sh s3://trendingtopics/archive/20090628/pages/ /mnt/pages
# TODO timeout s3cmd fetch if download takes longer than TIMEOUT seconds. 

SOURCE=$1
DESTINATION=$2

mkdir -p $DESTINATION
COUNTER=0
PAGES=`s3cmd ls  $SOURCE | awk '{ print $4 }'`
for filename in $PAGES
do
  echo "downloading $filename"
  TARGET=`echo $filename | cut -d'/' -f7`
  
  RETVAL=1
  while [ $RETVAL -ne 0 ]
  do
    s3cmd --force get $filename  $DESTINATION/part-$COUNTER
    RETVAL=$?
    if [ $RETVAL -eq 1  ]; then
      echo download attempt failed, pausing
      sleep 1
    fi
  done

  let COUNTER=COUNTER+1
done