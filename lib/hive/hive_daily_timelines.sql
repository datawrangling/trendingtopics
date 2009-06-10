CREATE TABLE raw_daily_stats_table (redirect_title STRING, dates STRING, pageviews STRING, total_pageviews BIGINT, monthly_trend DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE redirect_table (redirect_title STRING, true_title STRING, page_id BIGINT, page_latest BIGINT) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE pages (page_id BIGINT, url STRING, title STRING, page_latest BIGINT, total_pageviews BIGINT, monthly_trend DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE daily_timelines (page_id BIGINT, dates STRING, pageviews STRING, total_pageviews BIGINT) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE sample_pages (page_id BIGINT, url STRING, title STRING, page_latest BIGINT, total_pageviews BIGINT, monthly_trend DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

LOAD DATA LOCAL INPATH '/mnt/page_lookup_nonredirects.txt' OVERWRITE INTO TABLE redirect_table;

LOAD DATA INPATH 'finaloutput' INTO TABLE raw_daily_stats_table;

INSERT OVERWRITE TABLE pages
SELECT redirect_table.page_id, redirect_table.redirect_title, redirect_table.true_title, redirect_table.page_latest, raw_daily_stats_table.total_pageviews, raw_daily_stats_table.monthly_trend FROM redirect_table JOIN raw_daily_stats_table ON (redirect_table.redirect_title = raw_daily_stats_table.redirect_title);

INSERT OVERWRITE TABLE sample_pages
SELECT * FROM pages SORT BY monthly_trend DESC LIMIT 100;

INSERT OVERWRITE TABLE daily_timelines
SELECT redirect_table.page_id, raw_daily_stats_table.dates, raw_daily_stats_table.pageviews, raw_daily_stats_table.total_pageviews FROM redirect_table JOIN raw_daily_stats_table ON (redirect_table.redirect_title = raw_daily_stats_table.redirect_title);
