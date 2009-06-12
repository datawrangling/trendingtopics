drop table redirect_table;
drop table sample_pages;

CREATE TABLE redirect_table (redirect_title STRING, true_title STRING, page_id BIGINT, page_latest BIGINT) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE raw_daily_trends_table (redirect_title STRING, trend DOUBLE, error DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE daily_trends (page_id BIGINT, trend DOUBLE, error DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

CREATE TABLE sample_pages (page_id BIGINT, url STRING, title STRING, page_latest BIGINT, total_pageviews BIGINT, monthly_trend DOUBLE) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

LOAD DATA LOCAL INPATH '/mnt/page_lookup_nonredirects.txt' OVERWRITE INTO TABLE redirect_table;

LOAD DATA LOCAL INPATH '/mnt/sample_pages.txt' OVERWRITE INTO TABLE sample_pages;

LOAD DATA INPATH 'finaltrendoutput' INTO TABLE raw_daily_trends_table;

INSERT OVERWRITE TABLE daily_trends
SELECT redirect_table.page_id, raw_daily_trends_table.trend, raw_daily_trends_table.error FROM redirect_table JOIN raw_daily_trends_table ON (redirect_table.redirect_title = raw_daily_trends_table.redirect_title);

