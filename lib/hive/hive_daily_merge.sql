-- 1. import redirect table pulled from s3 to hdfs with distcp

CREATE TABLE redirect_table (
    redirect_title STRING, 
    true_title STRING, 
    page_id BIGINT, 
    page_latest BIGINT) 
  ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY '\t' 
  STORED AS TEXTFILE;

LOAD DATA INPATH 'wikidump' OVERWRITE INTO TABLE redirect_table;

-- 2. import raw_daily_pagecounts from streaming daily_merge job hdfs ouput dir.

CREATE TABLE raw_daily_pagecounts_table (
    redirect_title STRING,
    dates STRING,
  pageviews STRING) 
  ROW FORMAT DELIMITED
    FIELDS TERMINATED BY '\t'
  STORED AS TEXTFILE;
  
LOAD DATA INPATH 'finaloutput' INTO TABLE raw_daily_pagecounts_table;

-- 3. Pull old daily timelines table from S3 with distcp then load to Hive

CREATE TABLE daily_timelines (
    page_id BIGINT, 
    dates STRING, 
    pageviews STRING, 
    total_pageviews BIGINT) 
  ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY '\t' 
  STORED AS TEXTFILE;

-- later we will have the data in EBS snapshots with Cloudera Beta
LOAD DATA INPATH 'daily_timelines' OVERWRITE INTO TABLE daily_timelines;

-- 4. normalize python streaming output table "raw_daily_pagecounts" with page_id

CREATE TABLE daily_pagecounts_table (
    page_id BIGINT, 
    dates STRING, 
    pageviews STRING)
  ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY '\t' 
  STORED AS TEXTFILE;

INSERT OVERWRITE TABLE daily_pagecounts_table
SELECT redirect_table.page_id, raw_daily_pagecounts_table.dates, raw_daily_pagecounts_table.pageviews FROM redirect_table JOIN raw_daily_pagecounts_table ON (redirect_table.redirect_title = raw_daily_pagecounts_table.redirect_title);

--Time taken: 70.444 seconds
-- 2517783

-- 5. populate new_daily_timelines: merges old daily_timelines with new, inserts into "new_daily_timelines"
-- We do a left outer join, so that timelines with no new data don't get dropped entirely

CREATE TABLE new_daily_timelines (
    page_id BIGINT, 
    dates STRING, 
    pageviews STRING, 
    total_pageviews BIGINT) 
  ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY '\t' 
  STORED AS TEXTFILE;

INSERT OVERWRITE TABLE new_daily_timelines
SELECT DISTINCT u.page_id, u.dates, u.pageviews, u.total_pageviews 
FROM (
select dt.page_id, regexp_replace(dt.dates, ']', concat(',', concat(dp.dates, ']')) ) AS dates, regexp_replace(dt.pageviews, ']', concat(',', concat(dp.pageviews, ']')) ) AS pageviews,  cast(dt.total_pageviews as BIGINT) + cast(dp.pageviews as BIGINT) AS total_pageviews
FROM daily_timelines dt JOIN daily_pagecounts_table dp ON (dt.page_id = dp.page_id)
UNION ALL 
select dt.page_id, dt.dates, dt.pageviews, dt.total_pageviews
FROM daily_timelines dt LEFT OUTER JOIN daily_pagecounts_table dp ON (dt.page_id = dp.page_id) where dp.page_id is NULL) u;

-- Time taken: 896.042 seconds

INSERT OVERWRITE DIRECTORY 'new_daily_timelines' SELECT * FROM new_daily_timelines;
add FILE /mnt/trendingtopics/lib/python_streaming/hive_trend_mapper.py;

CREATE TABLE new_pages_raw (
    page_id BIGINT, 
    total_pageviews BIGINT, 
    monthly_trend DOUBLE, 
    daily_trend DOUBLE, 
    error DOUBLE) 
  ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY '\t' 
  STORED AS TEXTFILE;

INSERT OVERWRITE TABLE new_pages_raw
SELECT u.page_id, 
  u.total_pageviews, 
  u.monthly_trend, 
  u.daily_trend, 
  u.error   
FROM (        
  FROM new_daily_timelines ndt 
  MAP ndt.page_id, 
    ndt.dates, 
    ndt.pageviews, 
    ndt.total_pageviews 
  USING 'python hive_trend_mapper.py' 
  AS page_id, 
    total_pageviews, 
    monthly_trend, 
    daily_trend, 
    error) u;
    
-- Time taken: 1603.453 seconds

INSERT OVERWRITE DIRECTORY 'new_pages'
SELECT DISTINCT redirect_table.page_id, 
  redirect_table.redirect_title, 
  redirect_table.true_title, 
  redirect_table.page_latest, 
  new_pages_raw.total_pageviews, 
  new_pages_raw.monthly_trend, 
  new_pages_raw.daily_trend
    FROM redirect_table 
    JOIN new_pages_raw ON (redirect_table.page_id = new_pages_raw.page_id);