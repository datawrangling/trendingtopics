-- load_trends.sql


set foreign_key_checks=0; 
set sql_log_bin=0; 
set unique_checks=0;

ALTER TABLE daily_trends DISABLE KEYS;

drop index daily_trends_index on daily_trends;
truncate table daily_trends;

LOAD DATA LOCAL INFILE '/mnt/daily_trends.txt'
INTO TABLE daily_trends
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id,trend,error);

-- Matketing spammers
delete from daily_trends where page_id = 10447140;

create index daily_trends_index on daily_trends (page_id, trend);

ALTER TABLE daily_trends ENABLE KEYS;

set foreign_key_checks=1; 
set unique_checks=1;