#!/bin/sh
# run_daily_merge.sh

# Usage:
#
# run_daily_merge.sh MYBUCKET MYSERVER MAILTO NUMREDUCERS

# After the initial import of historical data, this script is run daily at 7:30 PM EST
# to calculate daily trends with the day's latest S3 data

# This date can be fetched by a SQL query against prod to see the latest date in timelines:

MYBUCKET=$1
MYSERVER=$2
MAILTO=$3
NUMREDUCERS=$4

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
  echo there are 24 files for $NEXTDATE, running daily merge
else
  # If there are more/less than 24 files (wc -l), then we abort and send an email to the admin
   echo the number of files for $NEXTDATE does not equal 24, attempting to fetch
   cd /mnt
   wget -r --quiet --no-directories --no-parent -L -A "pagecounts-$NEXTDATE*" http://dammit.lt/wikistats/
   s3cmd --config=/root/.s3cfg put --force /mnt/pagecounts-$NEXTDATE* s3://$MYBUCKET/wikistats/
fi  

HOURLYCOUNT=`s3cmd --config=/root/.s3cfg ls s3://$MYBUCKET/wikistats/pagecounts-$NEXTDATE* | grep pagecounts | wc -l`

if [ $HOURLYCOUNT -eq 24  ]; then
  # If there are 24 files, then we go ahead with the process:

   ssh -o StrictHostKeyChecking=no root@$MYSERVER "python /mnt/app/current/lib/scripts/hadoop_mailer.py run_daily_merge.sh starting $MYSERVER $MAILTO"
   # start the Hadoop streaming Python job, we use 10 c1.medium nodes for daily processing
   # set the default number of reducers using the following formula:
   # number of concurrent reducers per node * number of nodes * 1.75
   # for 10 c1.medium = 2 * 10 * 1.75 = 35
   # TODO replace with a Hive custom mapper & COUNT query
   hadoop jar /usr/lib/hadoop/contrib/streaming/hadoop-*-streaming.jar \
     -input s3n://$MYBUCKET/wikistats/pagecounts-$NEXTDATE* \
     -output finaloutput \
     -mapper "daily_merge.py mapper" \
     -reducer "daily_merge.py reducer" \
     -file '/mnt/trendingtopics/lib/python_streaming/daily_merge.py' \
     -jobconf mapred.reduce.tasks=$NUMREDUCERS \
     -jobconf mapred.job.name=daily_merge   
   
   # Clear the logs so Hive can load the daily pagecount data 
   hadoop fs -rmr finaloutput/_logs 
   
   # Collect the hourly timeline data and prepare for Hive import
   # resulting data will be in finaltimelineoutput in hdfs
   bash trendingtopics/lib/scripts/run_hourly_timelines.sh $MYBUCKET $MYSERVER $NUMREDUCERS  
   
   # Fetch wikipedia page id lookup table
   # s3cmd --force --config=/root/.s3cfg get s3://trendingtopics/wikidump/page_lookup_nonredirects.txt /mnt/page_lookup_nonredirects.txt
   hadoop distcp s3n://$MYBUCKET/wikidump/page_lookup_nonredirects.txt wikidump/page_lookup_nonredirects.txt
   hadoop fs -rmr wikidump/_distcp_logs*
   
   # we will send the latest version of these up to S3 again with another distcp later
   hadoop distcp s3n://$MYBUCKET/archive/$LASTDATE/daily_timelines daily_timelines
   hadoop fs -rmr daily_timelines/_distcp_logs*   
   
   # fetch the old page, timelines, & trends tables:
   # s3cmd --force --config=/root/.s3cfg get s3://$MYBUCKET/archive/$LASTDATE/trendsdb.tar.gz /mnt/trendsdb.tar.gz
   
   # # Quick hack to verify size of s3 download   
   # S3_DB_SIZE=`s3cmd ls s3://trendingtopics/archive/trendsdb.tar.gz | tail -1 | awk '{print $3}'`
   # LOCAL_DB_SIZE=`ls -l trendsdb.tar.gz | awk '{print $5}'`
   # if [ $S3_DB_SIZE != $LOCAL_DB_SIZE  ]; then {
   #   echo ERROR the MD5 for downloaded trendsdb.tar.gz did not equal the MD5 on S3, aborting run
   #   ssh -o StrictHostKeyChecking=no root@$MYSERVER "python /mnt/app/current/lib/scripts/hadoop_mailer.py run_daily_merge.sh FAILED $MYSERVER $MAILTO"      
   #   exit 1
   # }
   # fi
   # 
   # # unpack the old pages, timelines, trends table txt files:
   # cd /mnt
   # tar -xzvf trendsdb.tar.gz

   # Kick off the HiveQL script 
   hive -f  /mnt/trendingtopics/lib/hive/hive_daily_merge.sql     
   
   # distcp new_daily_timelines and new_pages up to s3
   
   hadoop distcp /user/root/new_pages s3n://$MYBUCKET/archive/$NEXTDATE/pages
   hadoop distcp /user/root/new_daily_timelines s3n://$MYBUCKET/archive/$NEXTDATE/daily_timelines
   hadoop distcp /user/root/new_hourly_timelines s3n://$MYBUCKET/archive/$NEXTDATE/hourly_timelines
   

   # # Spool the tab delimited data out of hive for bulk loading into MySQL
   # # This can be replaced with Sqoop later
   # hive -S -e 'SELECT * FROM new_pages' > /mnt/pages.txt
   # hive -S -e 'SELECT * FROM new_daily_timelines' > /mnt/daily_timelines.txt
   # hive -S -e 'SELECT * FROM new_daily_trends' > /mnt/daily_trends.txt   
   
   # PAGES_SIZE=`ls -l pages.txt | awk {'print $5'}`
   # # Quick Hack to check the size of the pages.txt file
   # if [ $PAGES_SIZE -eq 0  ]; then {
   #   echo ERROR the size of pages.txt was 0, aborting run
   #   ssh -o StrictHostKeyChecking=no root@$MYSERVER "python /mnt/app/current/lib/scripts/hadoop_mailer.py run_daily_merge.sh FAILED $MYSERVER $MAILTO"      
   #   exit 1
   # }
   # fi
   # 
   # 
   # # gzip the data and send to prod and S3
   # tar cvf - pages.txt daily_timelines.txt daily_trends.txt | gzip > /mnt/trendsdb.tar.gz
   # # real 8m7.590s
   # # user 7m31.984s
   # # sys  0m18.621s
   # 
   # #remove the old trendsdb files if they exist
   # ssh -o StrictHostKeyChecking=no root@$MYSERVER 'cd /mnt && rm -f trendsdb.tar.gz'  
   # ssh -o StrictHostKeyChecking=no root@$MYSERVER 'cd /mnt && rm -f pages.txt'  
   # ssh -o StrictHostKeyChecking=no root@$MYSERVER 'cd /mnt && rm -f daily_trends.txt'  
   # ssh -o StrictHostKeyChecking=no root@$MYSERVER 'cd /mnt && rm -f daily_timelines.txt'  
   # 
   # # copy over new trendsdb
   # scp /mnt/trendsdb.tar.gz root@$MYSERVER:/mnt/
   
   # Remaining processing happens on the db server: loading tables, rebuilding indexes, swapping tables, flushing caches 
   # until process has been debugged, skip starting db load
   # ssh -o StrictHostKeyChecking=no root@$MYSERVER 'cd /mnt && nohup bash /mnt/app/current/lib/scripts/daily_load.sh > daily_load.log 2>&1' &
   ssh -o StrictHostKeyChecking=no root@$MYSERVER "python /mnt/app/current/lib/scripts/hadoop_mailer.py run_daily_merge.sh complete $MYSERVER $MAILTO"   

else
  # If there are more/less than 24 files (wc -l), then we abort and send an email to the admin
   echo the number of files for $NEXTDATE does not equal 24, aborting daily merge
   ssh -o StrictHostKeyChecking=no root@$MYSERVER "python /mnt/app/current/lib/scripts/hadoop_mailer.py run_daily_merge.sh FAILED $MYSERVER $MAILTO"
fi







