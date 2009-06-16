#!/bin/sh
# run_daily_merge.sh

# Usage:
#
# run_daily_merge.sh MYBUCKET MYSERVER MAILTO

# After the initial import of historical data, this script is run daily at 7:30 PM EST
# to calculate daily trends with the day's latest S3 data

# This date can be fetched by a SQL query against prod to see the latest date in timelines:

MYBUCKET=$1
MYSERVER=$2
MAILTO=$3

# run this query remotely against prod from the Hadoop cluster....
# Use "The Beatles", page id = 29812, since it is the highest volume wikipedia article
RESULTSET=`ssh -o StrictHostKeyChecking=no root@$MYSERVER 'mysql -u root trendingtopics_production -e "select LEFT(RIGHT(dates,9),8) from daily_timelines where page_id=29812;"'`

LASTDATE=`echo $RESULTSET | awk '{print $2}'`
# echo $LASTDATE
# 20090612

# use unix 'date' to find next date...
NEXTDATE=`date --date "-d $LASTDATE +1 day" +"%Y%m%d"`
# echo $NEXTDATE
# 20090613
 
# We will attempt to list the set of files for the following day from S3.  There should be 24 files.
HOURLYCOUNT=`s3cmd --config=/root/.s3cfg ls s3://$MYBUCKET/wikistats/pagecounts-$NEXTDATE* | grep pagecounts | wc -l`
# echo $HOURLYCOUNT
# 24

if [ $HOURLYCOUNT -eq 24  ]; then
  # If there are 24 files, then we go ahead with the process:
   echo there are 24 files for $NEXTDATE, running daily merge
   ssh -o StrictHostKeyChecking=no root@$MYSERVER "python /mnt/app/current/lib/scripts/hadoop_mailer.py run_daily_merge.sh starting $MYSERVER $MAILTO"
   # start the Hadoop streaming Python job, we use 10 c1.medium nodes for daily processing
   # set the default number of reducers using the following formula:
   # number of concurrent reducers per node * number of nodes * 1.75
   # for 10 c1.medium = 2 * 10 * 1.75 = 35
   hadoop jar /usr/lib/hadoop/contrib/streaming/hadoop-*-streaming.jar \
     -input s3n://$MYBUCKET/wikistats/pagecounts-$NEXTDATE* \
     -output finaloutput \
     -mapper "daily_merge.py mapper1" \
     -reducer "daily_merge.py reducer1" \
     -file '/mnt/trendingtopics/lib/python_streaming/daily_merge.py' \
     -jobconf mapred.reduce.tasks=35 \
     -jobconf mapred.job.name=daily_merge   
   
   # Clear the logs so Hive can load the daily pagecount data 
   hadoop fs -rmr finaloutput/_logs   
   
   # Fetch wikipedia page id lookup table
   s3cmd --force --config=/root/.s3cfg get s3://trendingtopics/wikidump/page_lookup_nonredirects.txt /mnt/page_lookup_nonredirects.txt
   
   # fetch the old page, timelines, & trends tables:
   s3cmd --force --config=/root/.s3cfg get s3://$MYBUCKET/archive/trendsdb.tar.gz /mnt/trendsdb.tar.gz
   
   # unpack the old pages, timelines, trends table txt files:
   cd /mnt
   tar -xzvf trendsdb.tar.gz

   # Kick off the HiveQL script 
   hive -f  /mnt/trendingtopics/lib/hive/hive_daily_merge.sql     

   # Spool the tab delimited data out of hive for bulk loading into MySQL
   # This can be replaced with Sqoop later
   hive -S -e 'SELECT * FROM new_pages' > /mnt/new_pages.txt
   hive -S -e 'SELECT * FROM new_daily_timelines' > /mnt/new_daily_timelines.txt
   hive -S -e 'SELECT * FROM new_daily_trends' > /mnt/new_daily_trends.txt   
   
   # gzip the data and send to prod and S3
   tar cvf - new_pages.txt new_daily_timelines.txt new_daily_trends.txt | gzip > /mnt/trendsdb.tar.gz
   # real 8m7.590s
   # user 7m31.984s
   # sys  0m18.621s
   
   scp /mnt/trendsdb.tar.gz root@$MYSERVER:/mnt/
   # Remaining processing happens on the db server: loading tables, rebuilding indexes, swapping tables, flushing caches 
   ssh -o StrictHostKeyChecking=no root@$MYSERVER 'cd /mnt && nohup bash /mnt/app/current/lib/scripts/daily_load.sh $MYBUCKET $MYSERVER $MAILTO > daily_load.log &'
   ssh -o StrictHostKeyChecking=no root@$MYSERVER "python /mnt/app/current/lib/scripts/hadoop_mailer.py run_daily_merge.sh complete $MYSERVER $MAILTO"   

else
  # If there are more/less than 24 files (wc -l), then we abort and send an email to the admin
   echo the number of files for $NEXTDATE does not equal 24, aborting daily merge
   ssh -o StrictHostKeyChecking=no root@$MYSERVER "python /mnt/app/current/lib/scripts/hadoop_mailer.py run_daily_merge.sh FAILED $MYSERVER $MAILTO"
fi







