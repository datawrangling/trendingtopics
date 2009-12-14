CREATE TABLE redirect_table (
    redirect_title STRING, 
    true_title STRING, 
    page_id BIGINT, 
    page_latest BIGINT) 
  ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY '\t' 
  STORED AS TEXTFILE;

LOAD DATA INPATH 'wikidump' OVERWRITE INTO TABLE redirect_table;

CREATE TABLE pages (
 page_id BIGINT, 
 redirect_title STRING, 
 true_title STRING, 
 page_latest BIGINT, 
 total_pageviews BIGINT, 
 monthly_trend DOUBLE, 
 daily_trend DOUBLE) 
  ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY '\001' 
  STORED AS TEXTFILE;

LOAD DATA INPATH 'pages' OVERWRITE INTO TABLE pages;

CREATE TABLE living_people (
 page_id BIGINT, 
 category STRING) 
  ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY '\t' 
  STORED AS TEXTFILE;

LOAD DATA INPATH 'living_people' OVERWRITE INTO TABLE living_people;

CREATE TABLE links (
 page_id BIGINT, 
 pl_title STRING) 
  ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY '\t' 
  STORED AS TEXTFILE;

LOAD DATA INPATH 'links' OVERWRITE INTO TABLE links;

CREATE TABLE temp_backlinks (
	pl_title STRING,
  page_id BIGINT,
 	bl_title STRING,
  monthly_trend DOUBLE) 
  ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY '\001' 
  STORED AS TEXTFILE;

INSERT OVERWRITE TABLE temp_backlinks
select links.pl_title, pages.page_id, 
  pages.redirect_title, pages.monthly_trend
from links JOIN pages ON (pages.page_id = links.page_id);

CREATE TABLE backlinks (
  page_id BIGINT,
	bl_title STRING,
  daily_trend DOUBLE,
	monthly_trend DOUBLE,
	total_pageviews BIGINT) 
  ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY '\001' 
  STORED AS TEXTFILE;

INSERT OVERWRITE TABLE backlinks
select pages.page_id, temp_backlinks.bl_title, temp_backlinks.daily_trend, temp_backlinks.monthly_trend, temp_backlinks.total_pageviews 
from pages JOIN temp_backlinks ON (pages.redirect_title = temp_backlinks.pl_title);


CREATE TABLE mutual_links (
  page_id BIGINT,
	bl_title STRING,
  daily_trend DOUBLE,
	monthly_trend DOUBLE,
	total_pageviews BIGINT) 
  ROW FORMAT DELIMITED 
    FIELDS TERMINATED BY '\001' 
  STORED AS TEXTFILE;
  
INSERT OVERWRITE TABLE mutual_links
select links.page_id, backlinks.bl_title, backlinks.daily_trend, backlinks.monthly_trend, backlinks.total_pageviews 
from backlinks JOIN links ON (links.page_id = backlinks.page_id)
where links.pl_title = backlinks.bl_title;  

  
CREATE TABLE backlinks_reduced (
  page_id BIGINT,
	backlinks STRING) 
  ROW FORMAT DELIMITED 
  FIELDS TERMINATED BY '\001' 
  STORED AS TEXTFILE;

add FILE /mnt/hive_backlink_mapper.py;
add FILE /mnt/hive_backlink_reducer.py;

FROM (
  FROM backlinks
  MAP backlinks.page_id, backlinks.bl_title, backlinks.total_pageviews
  USING 'python hive_backlink_mapper.py'
  CLUSTER BY key) map_output
INSERT OVERWRITE TABLE backlinks_reduced
  REDUCE map_output.key, map_output.value
  USING 'python hive_backlink_reducer.py'
  AS page_id, backlinks;
  
CREATE TABLE mutual_links_reduced (
  page_id BIGINT,
	backlinks STRING) 
  ROW FORMAT DELIMITED 
  FIELDS TERMINATED BY '\001' 
  STORED AS TEXTFILE;  
  

FROM (
  FROM mutual_links
  MAP mutual_links.page_id, mutual_links.bl_title, mutual_links.monthly_trend
  USING 'python hive_backlink_mapper.py'
  CLUSTER BY key) map_output
INSERT OVERWRITE TABLE mutual_links_reduced
  REDUCE map_output.key, map_output.value
  USING 'python hive_backlink_reducer.py'
  AS page_id, backlinks;  
  
  
