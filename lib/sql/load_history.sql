-- load_history.sql
--
-- This is run after the initial daily timeline job to populate 
-- historical daily timelines and page metadata.  For 8 months of data:
--
-- $ time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/load_history.sql
-- real 49m56.652s
-- user 0m1.512s
-- sys  0m9.237s


-- load entity metadata tables...

set foreign_key_checks=0; 
set sql_log_bin=0; 
set unique_checks=0;

TRUNCATE TABLE people;
TRUNCATE TABLE companies;

ALTER TABLE people DISABLE KEYS;
ALTER TABLE companies DISABLE KEYS;

LOAD DATA LOCAL INFILE '/mnt/Living_people.txt'
INTO TABLE people
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id);
  
LOAD DATA LOCAL INFILE '/mnt/Companies_listed_on_the_New_York_Stock_Exchange.txt'
INTO TABLE companies
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id);

ALTER TABLE people ENABLE KEYS;
ALTER TABLE companies ENABLE KEYS;  

set foreign_key_checks=1; 
set unique_checks=1;  
  
-- load data tables
TRUNCATE TABLE new_pages;
TRUNCATE TABLE new_daily_timelines;
TRUNCATE TABLE new_hourly_timelines;

set foreign_key_checks=0; 
set sql_log_bin=0; 
set unique_checks=0;

ALTER TABLE new_pages DISABLE KEYS;
ALTER TABLE new_daily_timelines DISABLE KEYS;
ALTER TABLE new_hourly_timelines DISABLE KEYS;



LOAD DATA LOCAL INFILE '/mnt/pages.txt'
INTO TABLE new_pages
FIELDS TERMINATED BY 0x01
LINES TERMINATED BY '\n'
(id, url, title, page_latest, total_pageviews, monthly_trend, daily_trend);

-- Query OK, 2783939 rows affected (9 min 12.61 sec)
-- Records: 2783939  Deleted: 0  Skipped: 0  Warnings: 0

LOAD DATA LOCAL INFILE '/mnt/daily_timelines.txt'
INTO TABLE new_daily_timelines
FIELDS TERMINATED BY 0x01
LINES TERMINATED BY '\n'
(page_id, dates, pageviews, total_pageviews);

-- Query OK, 2783939 rows affected (3 min 56.88 sec)
-- Records: 2783939  Deleted: 0  Skipped: 0  Warnings: 0

LOAD DATA LOCAL INFILE '/mnt/hourly_timelines.txt'
INTO TABLE new_hourly_timelines
FIELDS TERMINATED BY 0x01
LINES TERMINATED BY '\n'
(page_id, datetimes, pageviews);


ALTER TABLE new_pages ENABLE KEYS;
ALTER TABLE new_daily_timelines ENABLE KEYS;
ALTER TABLE new_hourly_timelines ENABLE KEYS;

set foreign_key_checks=1; 
set unique_checks=1;

analyze TABLE new_pages;
analyze TABLE new_daily_timelines;
analyze TABLE new_hourly_timelines;