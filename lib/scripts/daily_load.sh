#!/bin/sh
# daily_load.sh MYBUCKET MYSERVER MAILTO
#
# This production script is triggered remotely by the Hadoop cluster
# TODO: pull these variables from /mnt/app/current/config/config.yml
# 
MYBUCKET=trendingtopics
MYSERVER=db.trendingtopics.org
WEBSERVER=trendingtopics.org
MAILTO=pete@datawrangling.com

echo MYBUCKET is $MYBUCKET
echo MYSERVER is $MYSERVER
echo MAILTO is $MAILTO

echo starting daily_load
echo `date`
# cd /mnt && tar -xzvf trendsdb.tar.gz

RESULTSET=`mysql -u root trendingtopics_production -e "select count(*) from information_schema.TABLES where Table_Name='new_pages' and TABLE_SCHEMA='trendingtopics_production';"`
NEWCOUNT=`echo $RESULTSET | awk '{print $2}'`

RESULTSET=`mysql -u root trendingtopics_production -e "select LEFT(RIGHT(dates,9),8) from daily_timelines where page_id=29812;"`
LASTDATE=`echo $RESULTSET | awk '{print $2}'`
NEXTDATE=`date --date "-d $LASTDATE +1 day" +"%Y%m%d"`
echo NEXTDATE is $NEXTDATE

# rename backup if staging tables don't exist:
if [ $NEWCOUNT -eq 0  ]; then
  echo renaming backup tables to staging tables
  time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/rename_backup_to_new.sql
else
  echo staging tables exist, loading data
fi  

# Fetch "People"
s3cmd --force --config=/root/.s3cfg get s3://trendingtopics/wikidump/Living_people.txt /mnt/Living_people.txt
# Fetch "Companies"
s3cmd --force --config=/root/.s3cfg get s3://trendingtopics/wikidump/Companies_listed_on_the_New_York_Stock_Exchange.txt /mnt/Companies_listed_on_the_New_York_Stock_Exchange.txt

# mkdir -p /mnt/pages
# COUNTER=0
# PAGES=`s3cmd --config=/root/.s3cfg ls  s3://trendingtopics/archive/$NEXTDATE/pages/ | awk '{ print $4 }'`
# for filename in $PAGES
# do
#   echo "downloading $filename"
#   TARGET=`echo $filename | cut -d'/' -f7`
#   s3cmd --config=/root/.s3cfg --force get $filename  /mnt/pages/part-$COUNTER
#   let COUNTER=COUNTER+1
# done


rm -rf /mnt/pages
rm -rf /mnt/daily_timelines
rm -rf /mnt/hourly_timelines
mkdir -p /mnt/pages
mkdir -p /mnt/daily_timelines
mkdir -p /mnt/hourly_timelines

# Fetch latest "pages" moved to S3 by distcp on Hadoop cluster
# bash /mnt/app/current/lib/scripts/S3fetch.sh s3://trendingtopics/archive/$NEXTDATE/pages/ /mnt/pages
s3cmd get --config=/root/.s3cfg -r s3://trendingtopics/archive/$NEXTDATE/pages/ /mnt/pages

# merge pages
echo merging page files
time cat pages/* | sort -n > pages.txt

PAGECOUNT=`wc -l pages.txt | cut -d ' ' -f 1`
echo $PAGECOUNT


if [ $PAGECOUNT -eq 0  ]; then
  
  echo Load failed, pagecount was zero
  echo "$MYSERVER Load failed, pagecount was zero" | mail -s "$MYSERVER load failed" $MAILTO
  
else  
  # mkdir -p /mnt/daily_timelines
  # COUNTER=0
  # PAGES=`s3cmd --config=/root/.s3cfg ls  s3://trendingtopics/archive/$NEXTDATE/daily_timelines/ | awk '{ print $4 }'`
  # for filename in $PAGES
  # do
  #   echo "downloading $filename"
  #   TARGET=`echo $filename | cut -d'/' -f7`
  #   s3cmd --config=/root/.s3cfg --force get $filename  /mnt/daily_timelines/part-$COUNTER
  #   let COUNTER=COUNTER+1
  # done

  # Fetch latest "daily_timelines" moved to S3 by distcp on Hadoop cluster
  # bash /mnt/app/current/lib/scripts/S3fetch.sh s3://trendingtopics/archive/$NEXTDATE/daily_timelines/ /mnt/daily_timelines
  s3cmd get --config=/root/.s3cfg -r s3://trendingtopics/archive/$NEXTDATE/daily_timelines/ /mnt/daily_timelines
  

  echo merging timeline files
  # merge daily timelines
  time cat daily_timelines/* > daily_timelines.txt
  # real	3m55.572s

  # Fetch latest "hourly_timelines" moved to S3 by distcp on Hadoop cluster
  # bash /mnt/app/current/lib/scripts/S3fetch.sh s3://trendingtopics/archive/$NEXTDATE/hourly_timelines/ /mnt/hourly_timelines
  s3cmd get --config=/root/.s3cfg -r s3://trendingtopics/archive/$NEXTDATE/hourly_timelines/ /mnt/hourly_timelines
  

  echo merging hourly timeline files
  # merge daily timelines
  time cat hourly_timelines/* > hourly_timelines.txt
  # real	3m55.572s


  # mysql load of "new tables"
  echo loading history tables
  time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/load_history.sql
  # real	76m53.573s

  # At this point we are ready to swap the MySQL tables if the new data looks good...
  # for now we will leave this as a manual step so we can QA the results.

  #Find the max date of this trendsdb
  # Use "The Beatles", page id = 29812, since it is the highest volume wikipedia article
  RESULTSET=`mysql -u root trendingtopics_production -e "select LEFT(RIGHT(dates,9),8) from new_daily_timelines where page_id=29812;"`

  MAXDATE=`echo $RESULTSET | awk '{print $2}'`
  # echo $LASTDATE
  # 20090612

  echo loading featured pages
  cd /mnt
  python /mnt/app/current/lib/scripts/generate_featured_pages.py -d $MAXDATE > /mnt/featured_pages.txt
  time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/load_featured_pages.sql

  time mysql -u root trendingtopics_production -e "UPDATE new_pages,new_featured_pages SET new_pages.featured=1 WHERE new_pages.id=new_featured_pages.page_id;"

  # echo archiving the data to S3
  # # back up the trendsdb data, this copy will be pulled by the next daily job
  # time s3cmd --config=/root/.s3cfg put trendsdb.tar.gz s3://$MYBUCKET/archive/trendsdb.tar.gz
  # # real  0m57.789s
  # 
  # # Archive the data by date
  # time s3cmd --config=/root/.s3cfg put trendsdb.tar.gz s3://$MYBUCKET/archive/$MAXDATE/trendsdb.tar.gz

  echo swapping staging tables to live site
  # We swap the new tables to go live automatically
  time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/rename_new_to_live.sql

  # Remove any flagged pages from the config.yml blacklist section
  cd /mnt/app/current && RAILS_ENV=production rake blacklist_articles --trace

  echo purging cache
  # need to call rake task on the web server...
  # make sure private keys to access the web server are on the db server in /root/.ssh
  ssh -o StrictHostKeyChecking=no root@$WEBSERVER 'cd /mnt/app/current && RAILS_ENV=production rake purge_cache > /mnt/purge_cache.log 2>&1' &

  echo sending completion email
  # Send an email signalling staging tables are ready
  echo "$MYSERVER staging tables ready for QA" | mail -s "$MYSERVER staging complete" $MAILTO

  echo daily_load finished
  echo `date`
fi  








