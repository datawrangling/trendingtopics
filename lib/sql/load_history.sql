-- this is run when the database is first created to populate 
-- historical daily timelines and page metadata

set foreign_key_checks=0; 
set sql_log_bin=0; 
set unique_checks=0;

ALTER TABLE pages DISABLE KEYS;
ALTER TABLE daily_timelines DISABLE KEYS;

LOAD DATA LOCAL INFILE '/mnt/pages.txt'
INTO TABLE pages
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(id, url, title, page_latest, total_pageviews, monthly_trend);

-- Query OK, 2783939 rows affected (9 min 12.61 sec)
-- Records: 2783939  Deleted: 0  Skipped: 0  Warnings: 0

LOAD DATA LOCAL INFILE '/mnt/daily_timelines.txt'
INTO TABLE daily_timelines
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id, dates, pageviews, total_pageviews);

-- Query OK, 2783939 rows affected (3 min 56.88 sec)
-- Records: 2783939  Deleted: 0  Skipped: 0  Warnings: 0

ALTER TABLE pages ENABLE KEYS;
ALTER TABLE daily_timelines ENABLE KEYS;

set foreign_key_checks=1; 
set unique_checks=1;

-- for autocomplete 'like' query
create index pages_autocomp_index on pages (title(64), total_pageviews);
-- Query OK, 2783939 rows affected (6 min 20.95 sec)
-- Records: 2783939  Duplicates: 0  Warnings: 0

-- for main pagination
create index pages_trend_index on pages (monthly_trend);
-- Query OK, 2783939 rows affected (1 min 25.65 sec)
-- Records: 2783939  Duplicates: 0  Warnings: 0

-- for sparklines
create index timeline_pageid_index on daily_timelines (page_id);
-- Query OK, 2783939 rows affected (4 min 19.52 sec)
-- Records: 2783939  Duplicates: 0  Warnings: 0



