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
# $ bash trendingtopics/lib/scripts/run_hourly_timelines.sh MYBUCKET MYSERVER NUMREDUCERS
#
# where MYSERVER is the database server (i.e. db.trendingtopics.org)
#
# uploads daily_timelines tab delimited files to S3 archive folder via distcp
# which are then bulk loaded into the Rails app hourly_timelines table.
#
#

MYBUCKET=$1
MYSERVER=$2
NUMREDUCERS=$3

# we need to key dates off of max date in DB

RESULTSET=`ssh -o StrictHostKeyChecking=no root@$MYSERVER 'mysql -u root trendingtopics_production -e "select LEFT(RIGHT(dates,9),8) from daily_timelines where page_id=29812;"'`

D1=`echo $RESULTSET | awk '{print $2}'`
# echo $LASTDATE
# 20090612

# use unix 'date' to find next date...
D0=`date --date "-d $D1 +1 day" +"%Y%m%d"`
D2=`date --date "-d $D1 -1 day" +"%Y%m%d"`
D3=`date --date "-d $D1 -2 day" +"%Y%m%d"`
D4=`date --date "-d $D1 -3 day" +"%Y%m%d"`
D5=`date --date "-d $D1 -4 day" +"%Y%m%d"`
D6=`date --date "-d $D1 -5 day" +"%Y%m%d"`
D7=`date --date "-d $D1 -6 day" +"%Y%m%d"`
D8=`date --date "-d $D1 -7 day" +"%Y%m%d"`
D9=`date --date "-d $D1 -8 day" +"%Y%m%d"`

# Run the streaming job on 10 nodes
hadoop jar /usr/lib/hadoop/contrib/streaming/hadoop-*-streaming.jar \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D0* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D1* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D2* \
  -output finaltimelineoutput \
  -mapper "hourly_timelines.py mapper" \
  -reducer "hourly_timelines.py reducer 72" \
  -file '/mnt/trendingtopics/lib/python_streaming/hourly_timelines.py' \
  -jobconf mapred.reduce.tasks=$NUMREDUCERS \
  -jobconf mapred.job.name=hourly_timeines

# Clear the logs so Hive can load the raw timeline data  
# hadoop fs -rmr finaltimelineoutput/_logs






  
