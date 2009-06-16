#!/bin/sh
# daily_load.sh MYBUCKET
#
# This production script is triggered remotely by the Hadoop cluster
MYBUCKET=$1
MYSERVER=$2
MAILTO=$3

cd /mnt && tar -xzvf trendsdb.tar.gz

RESULTSET=`mysql -u root trendingtopics_production -e "select count(*) from information_schema.TABLES where Table_Name='new_pages' and TABLE_SCHEMA='trendingtopics_production';"`

NEWCOUNT=`echo $RESULTSET | awk '{print $2}'`

# rename backup if staging tables don't exist:
if [ $NEWCOUNT -eq 0  ]; then
  echo renaming backup tables to staging tables
  time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/rename_backup_to_new.sql
else
  echo staging tables exist, loading data
fi  

# mysql load of "new tables"
echo loading history tables
time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/load_history.sql
echo loading trends table
time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/load_trends.sql

# At this point we are ready to swap the MySQL tables if the new data looks good...
# for now we will leave this as a manual step so we can QA the results.

# Send an email signalling staging tables are ready
echo "$MYSERVER staging tables ready for QA" | mail -s "$MYSERVER staging complete" $MAILTO

# We can swap the new tables to go live automatically, but comment out for now
# time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/rename_new_to_live.sql


# Archive the trendsdb data very time consuming do this *after* the MySQL load...
echo backing up data to S3
time s3cmd --config=/root/.s3cfg put trendsdb.tar.gz s3://$MYBUCKET/archive/trendsdb.tar.gz






