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

# Use "The Beatles", page id = 29812
RESULTSET=`mysql -u root trendingtopics_production -e 'select LEFT(RIGHT(dates,9),8) from daily_timelines where page_id=29812;'`  LASTDATE=`echo $RESULTSET | awk '{print $2}'`
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


# If there are less than 24 files (wc -l), then we abort and send an email to the admin

# If there are 24 files, then we go ahead with the process:



