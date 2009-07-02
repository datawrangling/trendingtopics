#!/bin/sh
# run_hourly_trends.sh
#
# Driver script for generating hourly timeline json data.
# Assumes input data is on S3 in MYBUCKET
#
# Usage:
#
# Replace the input paths with your bucket and the desired range
# then:
#
# $ bash trendingtopics/lib/scripts/run_hourly_timelines.sh MYBUCKET
#
# uploads daily_timelines tab delimited files to S3 archive folder via distcp
# which are then bulk loaded into the Rails app hourly_timelines table.
#
#

MYBUCKET=$1
DAYS=`s3cmd --config=/root/.s3cfg ls s3://$MYBUCKET/wikistats/* | awk '{print $4}' | tail -240 | cut -d'.' -f1 | cut -d'-' -f2 | sort -u`

# echo $DAYS
# 20090603 20090604 20090605 20090606 20090607 20090608 20090609 20090610 20090611 20090612

D0=`date --date "now -1 day" +"%Y%m%d"`
D1=`date --date "now -2 day" +"%Y%m%d"`
D2=`date --date "now -3 day" +"%Y%m%d"`
D3=`date --date "now -4 day" +"%Y%m%d"`
D4=`date --date "now -5 day" +"%Y%m%d"`
D5=`date --date "now -6 day" +"%Y%m%d"`
D6=`date --date "now -7 day" +"%Y%m%d"`
D7=`date --date "now -8 day" +"%Y%m%d"`
D8=`date --date "now -9 day" +"%Y%m%d"`
D9=`date --date "now -10 day" +"%Y%m%d"`

# Run the streaming job on 10 nodes
hadoop jar /usr/lib/hadoop/contrib/streaming/hadoop-*-streaming.jar \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D0* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D1* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D2* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D3* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D4* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D5* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D6* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D7* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D8* \
  -input s3n://$MYBUCKET/wikistats/pagecounts-$D9* \
  -output finaltimelineoutput \
  -mapper "hourly_timelines.py mapper" \
  -reducer "hourly_timelines.py reducer 10" \
  -file '/mnt/trendingtopics/lib/python_streaming/hourly_timelines.py' \
  -jobconf mapred.reduce.tasks=20 \
  -jobconf mapred.job.name=hourly_timeines

# Clear the logs so Hive can load the raw timeline data  
hadoop fs -rmr finaltimelineoutput/_logs






  
