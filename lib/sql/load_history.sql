-- load_history.sql
--
-- This is run after the initial daily timeline job to populate 
-- historical daily timelines and page metadata.  For 8 months of data:
--
-- $ time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/load_history.sql
-- real 49m56.652s
-- user 0m1.512s
-- sys  0m9.237s

TRUNCATE TABLE new_pages;
TRUNCATE TABLE new_daily_timelines;

--set foreign_key_checks=0; 
set sql_log_bin=0; 
--set unique_checks=0;

ALTER TABLE new_pages DISABLE KEYS;
ALTER TABLE new_daily_timelines DISABLE KEYS;

LOAD DATA LOCAL INFILE '/mnt/pages.txt'
INTO TABLE new_pages
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(id, url, title, page_latest, total_pageviews, monthly_trend);

-- Query OK, 2783939 rows affected (9 min 12.61 sec)
-- Records: 2783939  Deleted: 0  Skipped: 0  Warnings: 0

LOAD DATA LOCAL INFILE '/mnt/daily_timelines.txt'
INTO TABLE new_daily_timelines
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id, dates, pageviews, total_pageviews);

-- Query OK, 2783939 rows affected (3 min 56.88 sec)
-- Records: 2783939  Deleted: 0  Skipped: 0  Warnings: 0

ALTER TABLE new_pages ENABLE KEYS;
ALTER TABLE new_daily_timelines ENABLE KEYS;

delete from new_pages where id = 10447140;

--set foreign_key_checks=1; 
--set unique_checks=1;

-- for autocomplete 'like' query
create index new_pages_autocomp_index on new_pages (title(64), total_pageviews);
-- Query OK, 2783939 rows affected (6 min 20.95 sec)
-- Records: 2783939  Duplicates: 0  Warnings: 0

-- for main pagination
create index new_pages_trend_index on new_pages (monthly_trend);
-- Query OK, 2783939 rows affected (1 min 25.65 sec)
-- Records: 2783939  Duplicates: 0  Warnings: 0

-- for sparklines
create index new_timeline_pageid_index on new_daily_timelines (page_id);
-- Query OK, 2804057 rows affected (22 min 33.80 sec)
-- Records: 2804057  Duplicates: 0  Warnings: 0




