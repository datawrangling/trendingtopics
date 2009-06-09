-- The SQL in this file is used to preprocess the historical 
-- raw wikipedia dumps as part of building the AWS public dataset. 
-- The data is used to create MySQL a redirect
-- page_lookups table used by hadoop.

-- Grep for only namespace0 articles

-- grep '^[0-9]*       0       ' page.txt > page_namespace0.txt

DROP TABLE IF EXISTS `page`;
CREATE TABLE `page` (
  `page_id` int(8) unsigned NOT NULL,
  `page_namespace` int(11) NOT NULL default '0',
  `page_title` varchar(255) binary NOT NULL default '',
  `page_restrictions` tinyblob NOT NULL,
  `page_counter` bigint(20) unsigned NOT NULL default '0',
  `page_is_redirect` tinyint(1) unsigned NOT NULL default '0',
  `page_is_new` tinyint(1) unsigned NOT NULL default '0',
  `page_random` double unsigned NOT NULL default '0',
  `page_touched` varchar(14) binary NOT NULL default '',
  `page_latest` int(8) unsigned NOT NULL default '0',
  `page_len` int(8) unsigned NOT NULL default '0',
PRIMARY KEY  (`page_id`)
) TYPE=InnoDB;

LOAD DATA LOCAL INFILE '/mnt/wikidata/wikidump/page_namespace0.txt'
INTO TABLE page
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id,
page_namespace, 
page_title, 
page_restrictions, 
page_counter, 
page_is_redirect, 
page_is_new, 
page_random, 
page_touched, 
page_latest, 
page_len);
-- Query OK, 6222751 rows affected, 137 warnings (2 min 24.78 sec)

create index title_index on page (page_title(64));
-- Query OK, 6222751 rows affected (5 min 45.70 sec)
  
create index page_index on page (page_id);
-- Query OK, 6222751 rows affected (6 min 1.51 sec)
    

DROP TABLE IF EXISTS `redirect`;
CREATE TABLE `redirect` (
  `id` int(8) unsigned NOT NULL auto_increment,
  `rd_from` int(8) unsigned NOT NULL default '0',
  `rd_namespace` int(11) NOT NULL default '0',
  `rd_title` varchar(255) binary NOT NULL default '',
PRIMARY KEY  (`id`)
) TYPE=InnoDB;

-- grep '^[0-9]*        0       ' redirect.txt > redirect_namespace0.txt

LOAD DATA LOCAL INFILE '/mnt/wikidata/wikidump/redirect_namespace0.txt'
INTO TABLE redirect
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(rd_from, rd_namespace, rd_title);
-- Query OK, 3446196 rows affected, 1 warning (30.58 sec)

create index red_from_index on redirect (rd_from);
-- Query OK, 3446196 rows affected (56.78 sec)  

-- this query finds the "true page" for all redirect article titles
-- file produced is in /mnt/mysql_data/trendingtopics_production
select original_page.page_title redirect_title, 
  REPLACE(final_page.page_title, '_', ' ') true_title, 
  final_page.page_id, 
  final_page.page_latest
from page original_page, 
  page final_page, 
  redirect
where rd_from = original_page.page_id
and rd_title = final_page.page_title
INTO OUTFILE 'page_lookup_redirects.txt';
-- Query OK, 3401301 rows affected (12 min 4.92 sec)

-- at this point any "true" non-redirect pages will be missing from the map table.

-- If there is no matching row for the right table in the ON or USING 
-- part in a LEFT JOIN, a row with all columns set to NULL is used for
-- the right table. You can use this fact to find rows in a table that
-- have no counterpart in another table:
 
-- this file can also be used to populate the base Rails app table... 
SELECT page.page_title redirect_title, 
  REPLACE(page.page_title, '_', ' ') true_title,  
  page.page_id, 
  page.page_latest
  FROM page LEFT JOIN redirect ON page.page_id = redirect.rd_from
  WHERE redirect.rd_from IS NULL
  INTO OUTFILE 'page_lookup_nonredirects.txt';
-- Query OK, 2821319 rows affected (1 min 3.48 sec)

-- we can cat the result of this query with page_lookup_redirects.txt to get
-- a compelte mapping for all pages in the wikistats data.
-- could also try a union if that is faster, although probably not

-- cat page_lookup_nonredirects.txt page_lookup_redirects.txt > page_lookups.txt

DROP TABLE IF EXISTS `page_lookups`;
CREATE TABLE `page_lookups` (
  `id` int(8) unsigned NOT NULL auto_increment,  
  `redirect_title` varchar(255) binary NOT NULL default '',
  `true_title` varchar(255) binary NOT NULL default '',
  `page_id` int(8) unsigned NOT NULL,
  `page_latest` int(8) unsigned NOT NULL default '0',
PRIMARY KEY  (`id`)  
) TYPE=InnoDB;

LOAD DATA LOCAL INFILE '/mnt/wikidata/wikidump/page_lookups.txt'
INTO TABLE page_lookups
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(redirect_title, true_title, page_id, page_latest);
-- Query OK, 6222620 rows affected (1 min 6.82 sec)


-- for the rails app we want an indexed table of titles
-- scaffolding created a model that generated a "pages" table:
-- script/generate scaffold Page url:string title:string page_latest:integer 

-- script/generate scaffold DailyTimeline page:references dates:text pageviews:text total_pageviews:integer

-- other models:  

-- DailyTrend
-- WeeklyTrend

-- script/generate scaffold DailyTrend page:references trend:float error:float
-- script/generate scaffold WeeklyTrend page:references trend:float error:float




-- Maybe HourlyTimeline

-- set foreign_key_checks=0; 
-- set sql_log_bin=0; 
-- set unique_checks=0;

-- LOAD DATA LOCAL INFILE '/mnt/wikidata/wikidump/page_lookup_nonredirects.txt'
-- INTO TABLE pages
-- FIELDS TERMINATED BY '\t'
-- LINES TERMINATED BY '\n'
-- (url, title, id, page_latest);
-- Query OK, 2821319 rows affected (30.29 sec)

-- 
-- LOAD DATA LOCAL INFILE '/mnt/wikidata/wikidump/pages_sample.txt'
-- INTO TABLE pages
-- FIELDS TERMINATED BY '\t'
-- LINES TERMINATED BY '\n'
-- (id, url, title, page_latest, total_pageviews);
-- 
-- 
-- LOAD DATA LOCAL INFILE '/mnt/sample_daily_trends.txt'
-- INTO TABLE daily_trends
-- FIELDS TERMINATED BY '\t'
-- LINES TERMINATED BY '\n'
-- (page_id, trend, error);
-- 
-- LOAD DATA LOCAL INFILE '/mnt/sample_daily_trends.txt'
-- INTO TABLE weekly_trends
-- FIELDS TERMINATED BY '\t'
-- LINES TERMINATED BY '\n'
-- (page_id, trend, error);

-- LOAD DATA LOCAL INFILE '~/pages_sample.txt'
-- INTO TABLE pages
-- FIELDS TERMINATED BY '\t'
-- LINES TERMINATED BY '\n'
-- (id, url, title, page_latest, total_pageviews);


-- create a MYSQL index on the title field
-- create index pages_title_index on pages (title(64));
-- Query OK, 2821319 rows affected (1 min 13.23 sec)
-- 
-- set foreign_key_checks=1; 
-- set unique_checks=1;

--sed -i -e 's/\x01/   /g' daily_timelines_sample.txt

-- LOAD DATA LOCAL INFILE '/mnt/wikidata/wikidump/daily_timelines_sample.txt'
-- INTO TABLE daily_timelines
-- FIELDS TERMINATED BY '\t'
-- LINES TERMINATED BY '\n'
-- (page_id, dates, pageviews, total_pageviews);

-- LOAD DATA LOCAL INFILE '~/daily_timelines_sample.txt'
-- INTO TABLE daily_timelines
-- FIELDS TERMINATED BY '\t'
-- LINES TERMINATED BY '\n'
-- (page_id, dates, pageviews, total_pageviews);

-- create index timeline_totalviews_index on daily_timelines (total_pageviews);



-- mysql> select * from pages where title like 'Barack Obama';
-- +--------+--------------+--------------+-------------+------------+------------+
-- | id     | url          | title        | page_latest | created_at | updated_at |
-- +--------+--------------+--------------+-------------+------------+------------+
-- | 534366 | Barack_Obama | Barack Obama |   276223690 | NULL       | NULL       | 
-- +--------+--------------+--------------+-------------+------------+------------+
-- 1 row in set (0.00 sec)

-- no index on page_id in the following query...


-- 
-- mysql> select * from page_lookups where page_id = 534366;
-- +---------+------------------------------------------------+--------------+---------+-------------+
-- | id      | redirect_title                                 | true_title   | page_id | page_latest |
-- +---------+------------------------------------------------+--------------+---------+-------------+
-- |  219291 | Barack_Obama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151538 | Barak_Obama                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151539 | Barack_H._Obama                                | Barack Obama |  534366 |   276223690 | 
-- | 3151540 | Barack                                         | Barack Obama |  534366 |   276223690 | 
-- | 3151541 | Barack_Obama.                                  | Barack Obama |  534366 |   276223690 | 
-- | 3151542 | Barack_H_Obama                                 | Barack Obama |  534366 |   276223690 | 
-- | 3151543 | 44th_President_of_the_United_States            | Barack Obama |  534366 |   276223690 | 
-- | 3151544 | Barach_Obama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151545 | Senator_Barack_Obama                           | Barack Obama |  534366 |   276223690 | 
--    ....                                                                                   ....
-- 
-- | 3151644 | Rocco_Bama                                     | Barack Obama |  534366 |   276223690 | 
-- | 3151645 | Barack_Obama's                                 | Barack Obama |  534366 |   276223690 | 
-- | 3151646 | B._Obama                                       | Barack Obama |  534366 |   276223690 | 
-- +---------+------------------------------------------------+--------------+---------+-------------+
-- 110 rows in set (11.15 sec)    

-- for joining with:
-- 
-- $ grep '^en Barack' pagecounts-20090521-100001 
-- en Barack 8 1240112
-- en Barack%20Obama 1 1167
-- en Barack_H._Obama 1 142802
-- en Barack_H_Obama 3 428946
-- en Barack_H_Obama_Jr. 2 285780
-- en Barack_Hussein_Obama,_Junior 2 285606
-- en Barack_O%27Bama 1 142796
-- en Barack_Obama 701 139248439
-- en Barack_Obama%27s_first_100_days 2 143181
-- en Barack_Obama,_Jr 2 285755
-- en Barack_Obama,_Sr. 10 287685
-- en Barack_Obama_%22HOPE%22_poster 2 40896
-- en Barack_Obama_%22Hope%22_poster 13 321436
-- en Barack_Obama_(comic_character) 1 11123
-- en Barack_Obama_2009_presidential_inauguration 3 170683
-- en Barack_Obama_Muslim_rumor 2 287550







