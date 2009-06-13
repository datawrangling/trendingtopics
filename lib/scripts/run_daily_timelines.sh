#!/bin/sh
# run_daily_trends.sh
#
# Driver script for running daily timeline aggregation
# and monthly trend estimation. Assumes input data is on S3
# in MYBUCKET 
# 
#
# Usage:
#
# Replace the input paths with your bucket and the desired range
# then:
#
# $ bash trendingtopics/lib/scripts/run_daily_timelines.sh MYBUCKET MYSERVER MAILTO
#
# The streaming command has a hardcoded cutoff that requires a minimum of 
# 45 days of data
#
# Produces a tab delimited trend output file "daily_trends.txt" 
# and a normalized "pages.txt" in /mnt/trendsdb.tar.gz
# ready to bulk load into the Rails app MySQL db.
#
# To clean the output directories before running again:
#
# $ hadoop dfs -rmr stage1-output
# $ hadoop dfs -rmr finaloutput
#
# TODO: make the parameters configurable 
# TODO: convert to a rake task
ssh root@$2 'python /mnt/app/current/lib/scripts/hadoop_mailer.py run_daily_timelines.sh starting $2 $3'

# start the hadoop streaming jobs
hadoop jar /usr/lib/hadoop/contrib/streaming/hadoop-*-streaming.jar \
  -input s3n://$1/wikistats/pagecounts-200* \
  -output stage1-output \
  -mapper "daily_timelines.py mapper1" \
  -reducer "daily_timelines.py reducer1" \
  -file '/mnt/trendingtopics/lib/python_streaming/daily_timelines.py' \
  -jobconf mapred.reduce.tasks=40 \
  -jobconf mapred.job.name=daily_timelines_stage1  
hadoop jar /usr/lib/hadoop/contrib/streaming/hadoop-*-streaming.jar \
  -input stage1-output \
  -output finaloutput \
  -mapper "daily_timelines.py mapper2" \
  -reducer "daily_timelines.py reducer2 45" \
  -file '/mnt/trendingtopics/lib/python_streaming/daily_timelines.py' \
  -jobconf mapred.reduce.tasks=40 \
  -jobconf mapred.job.name=daily_timelines_stage2
  
# Clear the logs so Hive can load the raw trend data  
hadoop fs -rmr finaloutput/_logs

# Fetch wikipedia page id lookup table
s3cmd get s3://trendingtopics/wikidump/page_lookup_nonredirects.txt /mnt/page_lookup_nonredirects.txt

# Kick off the HiveQL script 
hive -f  /mnt/trendingtopics/lib/hive/hive_daily_timelines.sql  

# Spool the tab delimited data out of hive for bulk loading into MySQL
# This can be replaced with Sqoop later

hive -S -e 'SELECT * FROM pages' > /mnt/pages.txt
hive -S -e 'SELECT * FROM daily_timelines' > /mnt/daily_timelines.txt
hive -S -e 'SELECT * FROM sample_pages' > /mnt/sample_pages.txt
hive -S -e 'SELECT daily_timelines.* FROM sample_pages JOIN daily_timelines ON (sample_pages.page_id = daily_timelines.page_id)' > /mnt/sample_daily_timelines.txt

tar cvf - pages.txt daily_timelines.txt | gzip > /mnt/trendsdb.tar.gz
scp /mnt/trendsdb.tar.gz root@$2:/mnt/
s3cmd put trendsdb.tar.gz s3://$1/archive/`date --date "now -1 day" +"%Y%m%d"`/trendsdb.tar.gz
s3cmd put trendsdb.tar.gz s3://$1/archive/trendsdb.tar.gz
s3cmd put --force /mnt/sample* s3://$1/sampledata/
ssh root@$2 'cd /mnt && tar -xzvf trendsdb.tar.gz'
# need to do the table rename dance here...
ssh root@$2 'cd /mnt && mysql -u root trendingtopics_production < app/current/lib/sql/load_history.sql'
ssh root@$2 'python /mnt/app/current/lib/scripts/hadoop_mailer.py run_daily_timelines.sh complete $2 $3'






