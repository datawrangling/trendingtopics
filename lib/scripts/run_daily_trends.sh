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
# $ bash bash trendingtopics/lib/scripts/run_daily_trends.sh
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

# Run the streaming job on 10 nodes
hadoop jar /usr/lib/hadoop/contrib/streaming/hadoop-*-streaming.jar \
  -input s3n://trendingtopics/wikistats/pagecounts-2009052* \
  -input s3n://trendingtopics/wikistats/pagecounts-2009053* \
  -input s3n://trendingtopics/wikistats/pagecounts-200906* \
  -output finaltrendoutput \
  -mapper "daily_trends.py mapper" \
  -reducer "daily_trends.py reducer 10" \
  -file '/mnt/trendingtopics/lib/python_streaming/daily_trends.py' \
  -jobconf mapred.reduce.tasks=40 \
  -jobconf mapred.job.name=daily_trends

# Clear the logs so Hive can load the raw trend data  
hadoop fs -rmr finaltrendoutput/_logs

# Fetch wikipedia page id lookup table and sample page dataset from our first timeline job
s3cmd get s3://trendingtopics/wikidump/page_lookup_nonredirects.txt /mnt/page_lookup_nonredirects.txt
s3cmd get s3://trendingtopics/sampledata/sample_pages.txt /mnt/sample_pages.txt

# Kick off the HiveQL script 
hive -f  /mnt/trendingtopics/lib/hive/hive_daily_trends.sql

# Spool the tab delimited data out of hive for bulk loading into MySQL
# This can be replaced with Sqoop later

hive -S -e 'SELECT * FROM daily_trends' > /mnt/daily_trends.txt
hive -S -e 'SELECT daily_trends.* FROM sample_pages JOIN daily_trends ON (sample_pages.page_id = daily_trends.page_id)' > /mnt/sample_daily_trends.txt









  
