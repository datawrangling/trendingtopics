#!/bin/sh

# Quick hack to grab directory from S3 to local target directory using s3cmd
#
# assumes format is s3://trendingtopics/archive/20090702/daily_timelines/attempt_200907072330_0011_m_000068_1
#
# example usage:
# bash /mnt/app/current/lib/scripts/S3fetch.sh s3://trendingtopics/archive/20090628/pages/ /mnt/pages
# TODO Replace this script and timeout logic for s3cmd with custom s3 downloader  
# in ruby using right_aws

SOURCE=$1
DESTINATION=$2

mkdir -p $DESTINATION
COUNTER=0
PAGES=`s3cmd ls  $SOURCE | awk '{ print $4 }'`
for filename in $PAGES
do
  echo "downloading $filename"
  TARGET=`echo $filename | cut -d'/' -f7`
  PARTNAME=`echo $filename | cut -d'/' -f7 | cut -d'_' -f1-5`
  
  RETVAL=1
  while [ $RETVAL -ne 0 ]
  do
    # wait 20 seconds for each download to complete, else abort & retry
    bash /mnt/app/current/lib/scripts/cmdtimeout -t 60 s3cmd --force get $filename  $DESTINATION/$PARTNAME 
    RETVAL=$?
    if [ $RETVAL -eq 1  ]; then
      echo download attempt failed, pausing
      sleep 1
    fi
  done

  let COUNTER=COUNTER+1
done