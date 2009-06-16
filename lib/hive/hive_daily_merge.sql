-- 1. creates staging tables
CREATE TABLE raw_daily_pagecounts_table (redirect_title STRING, dates STRING, pageviews STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE daily_pagecounts_table (page_id BIGINT, dates STRING, pageviews STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE redirect_table (redirect_title STRING, true_title STRING, page_id BIGINT, page_latest BIGINT) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE pages (page_id BIGINT, url STRING, title STRING, page_latest BIGINT, total_pageviews BIGINT, monthly_trend DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE daily_timelines (page_id BIGINT, dates STRING, pageviews STRING, total_pageviews BIGINT) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

-- Create new tables

CREATE TABLE new_daily_timelines (page_id BIGINT, dates STRING, pageviews STRING, total_pageviews BIGINT) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE new_pages_raw (page_id BIGINT, total_pageviews BIGINT, monthly_trend DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE new_pages (page_id BIGINT, url STRING, title STRING, page_latest BIGINT, total_pageviews BIGINT, monthly_trend DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE new_daily_trends (page_id BIGINT, trend DOUBLE, error DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

-- 2. imports raw_daily_pagecounts from streaming job hdfs dir.

LOAD DATA INPATH 'finaloutput' INTO TABLE raw_daily_pagecounts_table;

-- 3. imports old pages, daily_timelines, redirect_lookup files from filesystem

LOAD DATA LOCAL INPATH '/mnt/page_lookup_nonredirects.txt' OVERWRITE INTO TABLE redirect_table;
LOAD DATA LOCAL INPATH '/mnt/pages.txt' OVERWRITE INTO TABLE pages;
-- 2804203 rows

LOAD DATA LOCAL INPATH '/mnt/daily_timelines.txt' OVERWRITE INTO TABLE daily_timelines;
-- Time taken: 274.38 seconds
-- 2804203 rows

-- 4. normalizes python streaming output table "raw_daily_pagecounts" with page_id

INSERT OVERWRITE TABLE daily_pagecounts_table
SELECT redirect_table.page_id, raw_daily_pagecounts_table.dates, raw_daily_pagecounts_table.pageviews FROM redirect_table JOIN raw_daily_pagecounts_table ON (redirect_table.redirect_title = raw_daily_pagecounts_table.redirect_title);
--Time taken: 70.444 seconds
-- 2517783

-- 5. populate new_daily_timelines: merges old daily_timelines with new, inserts into "new_daily_timelines"
-- We do a left outer join, so that timelines with no new data don't get dropped entirely

INSERT OVERWRITE TABLE new_daily_timelines
SELECT u.page_id, u.dates, u.pageviews, u.total_pageviews 
FROM (
select dt.page_id, regexp_replace(dt.dates, ']', concat(',', concat(dp.dates, ']')) ) AS dates, regexp_replace(dt.pageviews, ']', concat(',', concat(dp.pageviews, ']')) ) AS pageviews,  cast(dt.total_pageviews as BIGINT) + cast(dp.pageviews as BIGINT) AS total_pageviews
FROM daily_timelines dt JOIN daily_pagecounts_table dp ON (dt.page_id = dp.page_id)
UNION ALL 
select dt.page_id, dt.dates, dt.pageviews, dt.total_pageviews
FROM daily_timelines dt LEFT OUTER JOIN daily_pagecounts_table dp ON (dt.page_id = dp.page_id) where dp.page_id is NULL) u;
-- Total MapReduce jobs = 3
-- 2804203 Rows loaded to new_daily_timelines
-- Time taken: 1261.71 seconds


-- 6. populate new_pages: run "hive_monthly_trend.py" python streaming scripts from Hive, calc 30 day trend and total pageviews
--  insert to new_pages Hive table.

-- add the python file to the cache:
add FILE /mnt/trendingtopics/lib/python_streaming/hive_monthly_trend_mapper.py; 

-- run the monthly streaming job:        
INSERT OVERWRITE TABLE new_pages_raw
SELECT u.page_id, u.total_pageviews, u.monthly_trend   
FROM (        
FROM new_daily_timelines ndt  MAP ndt.page_id, ndt.dates, ndt.pageviews, ndt.total_pageviews USING 'python hive_monthly_trend_mapper.py' AS page_id, total_pageviews, monthly_trend) u;

-- join the output to pages table get urls, etc...
INSERT OVERWRITE TABLE new_pages
SELECT pages.page_id, pages.url, pages.title, pages.page_latest, new_pages_raw.total_pageviews, new_pages_raw.monthly_trend FROM pages JOIN new_pages_raw ON (pages.page_id = new_pages_raw.page_id);
          
-- 7. run "hive_daily_trend.py" python streaming scripts from Hive, calc daily trend for all articles
--  insert to new_daily_trends Hive table

add FILE /mnt/trendingtopics/lib/python_streaming/hive_daily_trend_mapper.py; 

-- run the daily streaming job (for now we will just use daily data, no hourly):

INSERT OVERWRITE TABLE new_daily_trends 
SELECT u.page_id, u.trend, u.error
FROM (          
FROM new_daily_timelines ndt  MAP ndt.page_id, ndt.dates, ndt.pageviews, ndt.total_pageviews USING 'python hive_daily_trend_mapper.py' AS page_id, trend, error) u;

-- to test you can add a where clause & limit and it will run *without* a full table scan

-- FROM new_daily_timelines ndt  MAP ndt.page_id, ndt.dates, ndt.pageviews, ndt.total_pageviews USING 'python hive_daily_trend_mapper.py' AS page_id, trend, error limit 10;


