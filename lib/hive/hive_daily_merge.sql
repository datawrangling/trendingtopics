# 1. creates staging tables
CREATE TABLE raw_daily_pagecounts_table (redirect_title STRING, date STRING, pageviews STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE daily_pagecounts_table (page_id BIGINT, date STRING, pageviews STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE redirect_table (redirect_title STRING, true_title STRING, page_id BIGINT, page_latest BIGINT) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE pages (page_id BIGINT, url STRING, title STRING, page_latest BIGINT, total_pageviews BIGINT, monthly_trend DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE daily_timelines (page_id BIGINT, dates STRING, pageviews STRING, total_pageviews BIGINT) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

# Create new tables

CREATE TABLE new_daily_timelines (page_id BIGINT, dates STRING, pageviews STRING, total_pageviews BIGINT) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE new_pages (page_id BIGINT, url STRING, title STRING, page_latest BIGINT, total_pageviews BIGINT, monthly_trend DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

# 2. imports raw_daily_pagecounts from streaming job hdfs dir.

LOAD DATA INPATH 'finaloutput' INTO TABLE raw_daily_pagecounts_table;

# 3. imports old pages, daily_timelines, redirect_lookup files from filesystem

LOAD DATA LOCAL INPATH '/mnt/page_lookup_nonredirects.txt' OVERWRITE INTO TABLE redirect_table;
LOAD DATA LOCAL INPATH '/mnt/pages.txt' OVERWRITE INTO TABLE pages;
LOAD DATA LOCAL INPATH '/mnt/daily_timelines.txt' OVERWRITE INTO TABLE daily_timelines;

# 4. normalizes python streaming output table "raw_daily_pagecounts" with page_id

INSERT OVERWRITE TABLE daily_pagecounts_table
SELECT redirect_table.page_id, raw_daily_pagecounts_table.date, raw_daily_pagecounts_table.pageviews, raw_daily_stats_table.total_pageviews FROM redirect_table JOIN raw_daily_pagecounts_table ON (redirect_table.redirect_title = raw_daily_pagecounts_table.redirect_title);

# 5. populate new_daily_timelines: merges old daily_timelines with new, inserts into "new_daily_timelines"



# 6. populate new_pages: run "monthly trend" python streaming script from Hive, calc 30 day trend and total pageviews
#  insert to new_pages Hive table.


# 7. run daily_trend python streaming script from Hive, calc daily trend for all articles
#  insert to new_daily_trends Hive table


