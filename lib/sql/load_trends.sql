-- load_trends.sql

set unique_checks=0;
set foreign_key_checks=0; 
set sql_log_bin=0; 

TRUNCATE TABLE new_daily_trends;
ALTER TABLE new_daily_trends DISABLE KEYS;
CALL dropindex('new_daily_trends', 'daily_trends_index');


LOAD DATA LOCAL INFILE '/mnt/daily_trends.txt'
INTO TABLE new_daily_trends
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id,trend,error);

create index daily_trends_index on new_daily_trends (page_id, trend);

ALTER TABLE new_daily_trends ENABLE KEYS;

set foreign_key_checks=1; 
set unique_checks=1;