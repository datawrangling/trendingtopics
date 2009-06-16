#!/bin/sh
# daily_load.sh MYBUCKET
#
# This production script is triggered remotely by the Hadoop cluster
MYBUCKET=$1

cd /mnt && tar -xzvf trendsdb.tar.gz
# mysql load of "new tables"
time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/load_history.sql
time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/load_trends.sql

# Archive the trendsdb data very time consuming do this *after* the MySQL load...
s3cmd --config=/root/.s3cfg put trendsdb.tar.gz s3://$MYBUCKET/archive/trendsdb.tar.gz

# at this point we are ready to swap the MySQL tables if the new data looks good...
# for now we will leave this as a manual step so we can QA the results.
