hadoop distcp s3n://trendingtopics/wikidump/page_lookup_nonredirects.txt wikidump/page_lookup_nonredirects.txt
hadoop fs -rmr wikidump/_distcp_logs*

hadoop distcp s3n://trendingtopics/archive/20090816/daily_timelines daily_timelines
hadoop fs -rmr daily_timelines/_distcp_logs*

hadoop distcp s3n://trendingtopics/archive/20090816/pages pages
hadoop fs -rmr pages/_distcp_logs*

hadoop distcp s3n://trendingtopics/wikidump/Living_people.txt living_people/Living_people.txt
hadoop fs -rmr living_people/_distcp_logs*


hadoop distcp s3n://trendingtopics/wikidump/links links
hadoop fs -rmr links/_distcp_logs*

hive -f /mnt/app/current/lib/hive/hive_backlinks.sql