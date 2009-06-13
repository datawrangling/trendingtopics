#!/bin/sh
# run_daily_trends.sh
#
# Driver script for running daily trend estimation.
# Assumes input data is on S3
#
# Usage:
#
# Replace the input paths with your bucket and the desired range
# then:
#
# $ bash trendingtopics/lib/scripts/run_daily_trends.sh s3n://trendingtopics/wikistats/pagecounts-200906* s3n://trendingtopics/wikistats/pagecounts-2009053*
#
# Produces a tab delimited trend output file "/mnt/daily_trends.txt" 
# ready to bulk load into the Rails app daily_trends table.
#
#!/bin/sh
# run_daily_trends.sh
#
# Driver script for running daily trend estimation.
# Assumes input data is on S3 in MYBUCKET
#
# Usage:
#
# Replace the input paths with your bucket and the desired range
# then:
#
# $ bash trendingtopics/lib/scripts/run_daily_trends.sh MYBUCKET
#
# Produces a tab delimited trend output file "/mnt/daily_trends.txt" 
# ready to bulk load into the Rails app daily_trends table.
#
# To clean the output directory before running again:
#
# $ hadoop dfs -rmr finaltrendoutput
#
# TODO: make the parameters configurable 
# TODO: convert to a rake task
# TODO: replace evil hack to get the last 10 days of data from S3


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
  -input s3n://$1/wikistats/pagecounts-$D0* \
  -input s3n://$1/wikistats/pagecounts-$D1* \
  -input s3n://$1/wikistats/pagecounts-$D2* \
  -input s3n://$1/wikistats/pagecounts-$D3* \
  -input s3n://$1/wikistats/pagecounts-$D4* \
  -input s3n://$1/wikistats/pagecounts-$D5* \
  -input s3n://$1/wikistats/pagecounts-$D6* \
  -input s3n://$1/wikistats/pagecounts-$D7* \
  -input s3n://$1/wikistats/pagecounts-$D8* \
  -input s3n://$1/wikistats/pagecounts-$D9* \
  -output finaltrendoutput \
  -mapper "daily_trends.py mapper" \
  -reducer "daily_trends.py reducer 10" \
  -file '/mnt/trendingtopics/lib/python_streaming/daily_trends.py' \
  -jobconf mapred.reduce.tasks=40 \
  -jobconf mapred.job.name=daily_trends

# Clear the logs so Hive can load the raw trend data  
hadoop fs -rmr finaltrendoutput/_logs

# Fetch wikipedia page id lookup table and sample page dataset from our first timeline job
s3cmd get --force s3://trendingtopics/wikidump/page_lookup_nonredirects.txt /mnt/page_lookup_nonredirects.txt
s3cmd get --force s3://trendingtopics/sampledata/sample_pages.txt /mnt/sample_pages.txt

# Kick off the HiveQL script 
hive -f  /mnt/trendingtopics/lib/hive/hive_daily_trends.sql

# Spool the tab delimited data out of hive for bulk loading into MySQL
# This can be replaced with Sqoop later

hive -S -e 'SELECT * FROM daily_trends' > /mnt/daily_trends.txt
hive -S -e 'SELECT daily_trends.* FROM sample_pages JOIN daily_trends ON (sample_pages.page_id = daily_trends.page_id)' > /mnt/sample_daily_trends.txt





  
