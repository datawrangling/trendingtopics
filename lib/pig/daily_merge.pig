REGISTER /usr/lib/pig/contrib/piggybank/java/piggybank.jar;
DEFINE REPLACE org.apache.pig.piggybank.evaluation.string.REPLACE();

-- 1. import redirect table pulled from s3 to hdfs with distcp
redirects = LOAD 'wikidump' AS (redirect_title:chararray, 
  true_title:chararray, page_id:long, page_latest:long);

-- 2.5 import raw_hourly_timelines from streaming hourly job hdfs dir
raw_hourly_timelines = LOAD 'finaltimelineoutput' AS (redirect_title:chararray, 
  dates:chararray, pageviews:chararray);

-- 2.6 normalize hourly pagecounts and ready for export
-- 0 redirect_title, 1 page_id, 2 redirect_title, 3 dates, 4 pageviews
redirect_map = FOREACH redirects GENERATE redirect_title, page_id;
joined_redirect_timelines = JOIN redirect_map BY redirect_title, raw_hourly_timelines BY redirect_title PARALLEL 35;
new_hourly_timelines = FOREACH joined_redirect_timelines GENERATE $1 as page_id, $3 as dates, $4 as pageviews;
STORE new_hourly_timelines INTO 'new_hourly_timelines' USING PigStorage('\u0001');

-- 2. import raw_daily_pagecounts from streaming daily_merge job hdfs ouput dir.
raw_daily_pagecounts = LOAD 'finaloutput' AS (redirect_title:chararray, 
  dates:chararray, pageviews:chararray);

-- 3. Pull old daily timelines table from S3 with distcp then load to Hive
daily_timelines = LOAD 'daily_timelines' USING PigStorage('\u0001') AS (page_id:long, 
  dates:chararray, pageviews:chararray, total_pageviews:long);

-- 4. normalize python streaming output table "raw_daily_pagecounts" with page_id
joined_redirect_dailycounts = JOIN redirect_map BY redirect_title, raw_daily_pagecounts BY redirect_title PARALLEL 35;
daily_pagecounts = FOREACH joined_redirect_dailycounts GENERATE $1 as page_id, $3 as dates, $4 as pageviews;

-- 5. populate new_daily_timelines: merges old daily_timelines with new
-- We do a left outer join, so that timelines with no new data don't get dropped entirely

-- cogroup daily_timelines with daily_pagecounts on page_id (will include nulls on either side)

joined_daily = cogroup daily_timelines by page_id, daily_pagecounts by page_id PARALLEL 35;

--grunt> describe joined_daily;
--joined_daily: {group: long,daily_timelines: {page_id: long,dates: chararray,pageviews: chararray,total_pageviews: long},daily_pagecounts: {page_id: long,dates: chararray,pageviews: chararray}}


-- filter out pages with no timeline history on the left
joined_daily = filter joined_daily by COUNT(daily_timelines) > 0;
split joined_daily into new_values if COUNT(daily_pagecounts) > 0, no_new_value if COUNT(daily_pagecounts) == 0;

-- for pages without a new entry on the right, just emit the old timeline...
new_daily_timelines_A = FOREACH no_new_value GENERATE FLATTEN(daily_timelines) AS (page_id:long, 
  dates:chararray, pageviews:chararray, total_pageviews:long);

-- for pages with a new entry on the right, merge the pagecount into the timeline & sum tot_pageviews
new_daily_timelines_B = FOREACH new_values GENERATE FLATTEN(daily_timelines) AS (page_id:long, 
  dates:chararray, pageviews:chararray, total_pageviews:long), FLATTEN(daily_pagecounts) AS (d_page_id:long, d_dates:chararray, d_pageviews:chararray);

--   grunt> describe new_daily_timelines_B;                                                                                                    new_daily_timelines_B: {page_id: long,dates: chararray,pageviews: chararray,total_pageviews: long,d_page_id: long,d_dates: chararray,d_pageviews: chararray}
new_daily_timelines_B = FOREACH new_daily_timelines_B GENERATE page_id, 
REPLACE(dates, ']', CONCAT(',', CONCAT(d_dates,']') )) as dates,
REPLACE(pageviews, ']', CONCAT(',', CONCAT(d_pageviews,']') )) as pageviews,
(long)total_pageviews + (long)d_pageviews as total_pageviews;
-- union the two resultsets...
new_daily_timelines = UNION new_daily_timelines_B, new_daily_timelines_A; 
-- save as 'new_daily_timelines'
STORE new_daily_timelines INTO 'new_daily_timelines' USING PigStorage('\u0001');

new_daily_timelines = LOAD 'new_daily_timelines' USING PigStorage('\u0001') AS (page_id:long, 
  dates:chararray, pageviews:chararray, total_pageviews:long);

-- 6. Run streaming code on latest timelines to get monthly and daily trends, save as 'new_pages_raw'

DEFINE trend_mapper `hive_trend_mapper.py`
  SHIP ('/mnt/trendingtopics/lib/python_streaming/hive_trend_mapper.py');
new_pages_raw = STREAM new_daily_timelines THROUGH trend_mapper
  AS (page_id:long, total_pageviews:long, monthly_trend:float, daily_trend:float, error:float);
  
-- 7. join streaming trend results with full redirect table to get page titles, save as 'new_pages'
new_pages = JOIN redirects BY page_id, new_pages_raw BY page_id PARALLEL 35;
new_pages = FOREACH new_pages GENERATE $2 as page_id, $0 as redirect_title, $1 as true_title, $3 as page_latest, $5 as total_pageviews, $6 as monthly_trend, $7 as daily_trend;

-- store needed results into hdfs
STORE new_pages INTO 'new_pages' USING PigStorage('\u0001');