#!/bin/sh
# run_hourly_trends.sh
#
# Driver script for generating hourly timeline json data.
# Assumes input data is on S3 in MYBUCKET grabs the last 10 days of data
#
# Usage:
#
# Replace the input paths with your bucket
#
# then:
#
# $ bash trendingtopics/lib/scripts/run_hourly_timelines.sh MYBUCKET MYSERVER
#
# where MYSERVER is the database server (i.e. db.trendingtopics.org)
#
# uploads daily_timelines tab delimited files to S3 archive folder via distcp
# which are then bulk loaded into the Rails app hourly_timelines table.
#
#

MYBUCKET=$1
MYSERVER=$2

# we need to key dates off of max date in DB

RESULTSET=`ssh -o StrictHostKeyChecking=no root@$MYSERVER 'mysql -u root trendingtopics_production -e "select LEFT(RIGHT(dates,9),8) from daily_timelines where page_id=29812;"'`

LASTDATE=`echo $RESULTSET | awk '{print $2}'`
# echo $LASTDATE
# 20090612

# use unix 'date' to find next date...
NEXTDATE=`date --date "-d $LASTDATE +1 day" +"%Y%m%d"`
PREVDATE=`date --date "-d $LASTDATE +1 day" +"%Y%m%d"`

# Run the streaming job on 10 nodes
hadoop jar /usr/lib/hadoop/contrib/streaming/hadoop-*-streaming.jar \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$PREVDATE* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$LASTDATE* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$NEXTDATE* \
  -output finaltimelineoutput \
  -mapper "hourly_timelines.py mapper" \
  -reducer "hourly_timelines.py reducer 72" \
  -file '/mnt/trendingtopics/lib/python_streaming/hourly_timelines.py' \
  -jobconf mapred.reduce.tasks=20 \
  -jobconf mapred.job.name=hourly_timeines

# Clear the logs so Hive can load the raw timeline data  
hadoop fs -rmr finaltimelineoutput/_logs






  
