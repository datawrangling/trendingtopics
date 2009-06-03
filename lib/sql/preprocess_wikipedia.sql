-- The SQL in this file is used to preprocess the historical 
-- raw wikipedia dumps in the AWS public dataset.  The data 
-- is used to populate the Rails app MySQL pages table and the
-- page_lookups table.

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
-- MonthlyTrend

-- Maybe HourlyTimeline

set foreign_key_checks=0; 
set sql_log_bin=0; 
set unique_checks=0;

LOAD DATA LOCAL INFILE '/mnt/wikidata/wikidump/page_lookup_nonredirects.txt'
INTO TABLE pages
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(url, title, id, page_latest);
-- Query OK, 2821319 rows affected (30.29 sec)

-- 
-- LOAD DATA LOCAL INFILE '/mnt/wikidata/wikidump/pages_sample.txt'
-- INTO TABLE pages
-- FIELDS TERMINATED BY '\t'
-- LINES TERMINATED BY '\n'
-- (id, url, title, page_latest);

-- LOAD DATA LOCAL INFILE '~/newpages.txt'
-- INTO TABLE pages
-- FIELDS TERMINATED BY '\t'
-- LINES TERMINATED BY '\n'
-- (id, url, title, page_latest, total_pageviews);


-- create a MYSQL index on the title field
create index pages_title_index on pages (title(64));
-- Query OK, 2821319 rows affected (1 min 13.23 sec)

set foreign_key_checks=1; 
set unique_checks=1;

--sed -i -e 's/\x01/   /g' daily_timelines_sample.txt

LOAD DATA LOCAL INFILE '/mnt/wikidata/wikidump/daily_timelines_sample.txt'
INTO TABLE daily_timelines
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id, dates, pageviews, total_pageviews);

-- LOAD DATA LOCAL INFILE '~/daily_timelines_sample.txt'
-- INTO TABLE daily_timelines
-- FIELDS TERMINATED BY '\t'
-- LINES TERMINATED BY '\n'
-- (page_id, dates, pageviews, total_pageviews);

create index timeline_totalviews_index on daily_timelines (total_pageviews);



-- mysql> select * from pages where title like 'Barack Obama';
-- +--------+--------------+--------------+-------------+------------+------------+
-- | id     | url          | title        | page_latest | created_at | updated_at |
-- +--------+--------------+--------------+-------------+------------+------------+
-- | 534366 | Barack_Obama | Barack Obama |   276223690 | NULL       | NULL       | 
-- +--------+--------------+--------------+-------------+------------+------------+
-- 1 row in set (0.00 sec)

-- no index on page_id in the following query...

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
-- | 3151546 | Borrack_Obama                                  | Barack Obama |  534366 |   276223690 | 
-- | 3151547 | Barrak_Obama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151548 | Barrack_Obama                                  | Barack Obama |  534366 |   276223690 | 
-- | 3151549 | Senator_Obama                                  | Barack Obama |  534366 |   276223690 | 
-- | 3151550 | Barack_obama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151551 | Barry_Obama                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151552 | Barack_Hussein_Obama,_Jr.                      | Barack Obama |  534366 |   276223690 | 
-- | 3151553 | Barack_Hussein_Obama,_Jr                       | Barack Obama |  534366 |   276223690 | 
-- | 3151554 | Barack_Hussein_Obama_Jr                        | Barack Obama |  534366 |   276223690 | 
-- | 3151555 | Barack_Hussein_Obama_Jr.                       | Barack Obama |  534366 |   276223690 | 
-- | 3151556 | Barack_H._Obama,_Jr.                           | Barack Obama |  534366 |   276223690 | 
-- | 3151557 | Barack_H._Obama,_Jr                            | Barack Obama |  534366 |   276223690 | 
-- | 3151558 | Barack_H._Obama_Jr                             | Barack Obama |  534366 |   276223690 | 
-- | 3151559 | Barack_H._Obama_Jr.                            | Barack Obama |  534366 |   276223690 | 
-- | 3151560 | Barack_H_Obama,_Jr.                            | Barack Obama |  534366 |   276223690 | 
-- | 3151561 | Barack_H_Obama,_Jr                             | Barack Obama |  534366 |   276223690 | 
-- | 3151562 | Barack_H_Obama_Jr.                             | Barack Obama |  534366 |   276223690 | 
-- | 3151563 | Barack_H_Obama_Jr                              | Barack Obama |  534366 |   276223690 | 
-- | 3151564 | Barack_Obama_Jr                                | Barack Obama |  534366 |   276223690 | 
-- | 3151565 | Barack_Obama,_Jr.                              | Barack Obama |  534366 |   276223690 | 
-- | 3151566 | Barack_Obama_Jr.                               | Barack Obama |  534366 |   276223690 | 
-- | 3151567 | Barack_Obama,_Jr                               | Barack Obama |  534366 |   276223690 | 
-- | 3151568 | Barack_Hussein_Obama,_Junior                   | Barack Obama |  534366 |   276223690 | 
-- | 3151569 | Barack_Hussein_Obama_Junior                    | Barack Obama |  534366 |   276223690 | 
-- | 3151570 | Barack_H_Obama_Junior                          | Barack Obama |  534366 |   276223690 | 
-- | 3151571 | Barack_H_Obama,_Junior                         | Barack Obama |  534366 |   276223690 | 
-- | 3151572 | Barack_H._Obama,_Junior                        | Barack Obama |  534366 |   276223690 | 
-- | 3151573 | Barack_H._Obama_Junior                         | Barack Obama |  534366 |   276223690 | 
-- | 3151574 | Barack_Obama_Junior                            | Barack Obama |  534366 |   276223690 | 
-- | 3151575 | Barack_Obama,_Junior                           | Barack Obama |  534366 |   276223690 | 
-- | 3151576 | Barak_hussein_obama                            | Barack Obama |  534366 |   276223690 | 
-- | 3151577 | O'Bama                                         | Barack Obama |  534366 |   276223690 | 
-- | 3151578 | Bacak_Obama                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151579 | Obama                                          | Barack Obama |  534366 |   276223690 | 
-- | 3151580 | Barak_obama                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151581 | Barack_Obamba                                  | Barack Obama |  534366 |   276223690 | 
-- | 3151582 | Obama_Barack                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151583 | Obama,_Barack                                  | Barack Obama |  534366 |   276223690 | 
-- | 3151584 | Hussein_Obama                                  | Barack Obama |  534366 |   276223690 | 
-- | 3151585 | Barac_Obama                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151586 | Barac_obama                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151587 | O'bama                                         | Barack Obama |  534366 |   276223690 | 
-- | 3151588 | Barok_Oboma                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151589 | Baruch_Obama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151590 | Berack_Obama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151591 | Barrack_Hussein_Obama                          | Barack Obama |  534366 |   276223690 | 
-- | 3151592 | B._Hussein_Obama                               | Barack Obama |  534366 |   276223690 | 
-- | 3151593 | President_Obama                                | Barack Obama |  534366 |   276223690 | 
-- | 3151594 | Barack_Hussein_Obama_II                        | Barack Obama |  534366 |   276223690 | 
-- | 3151595 | Sen._Obama                                     | Barack Obama |  534366 |   276223690 | 
-- | 3151596 | Barack_H._Obama_II                             | Barack Obama |  534366 |   276223690 | 
-- | 3151597 | Berrack_Obama                                  | Barack Obama |  534366 |   276223690 | 
-- | 3151598 | Berrak_Obama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151599 | Berak_Obama                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151600 | Barock_obama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151601 | Barack_OBama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151602 | Barack_Obbama                                  | Barack Obama |  534366 |   276223690 | 
-- | 3151603 | Barack_O'Bama                                  | Barack Obama |  534366 |   276223690 | 
-- | 3151604 | Barack_Hussein_Obama                           | Barack Obama |  534366 |   276223690 | 
-- | 3151605 | Burack_obama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151606 | Barack_Hussein                                 | Barack Obama |  534366 |   276223690 | 
-- | 3151607 | Barack_Obama_II                                | Barack Obama |  534366 |   276223690 | 
-- | 3151608 | Barak_Obamba                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151609 | Ob_ama                                         | Barack Obama |  534366 |   276223690 | 
-- | 3151610 | OBAMA                                          | Barack Obama |  534366 |   276223690 | 
-- | 3151611 | Barry_O'Bama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151612 | Obamessiah                                     | Barack Obama |  534366 |   276223690 | 
-- | 3151613 | 2008_Democratic_Presidential_Nominee           | Barack Obama |  534366 |   276223690 | 
-- | 3151614 | Obahma                                         | Barack Obama |  534366 |   276223690 | 
-- | 3151615 | Barak_O'Bama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151616 | Barack_Obama_Presidential_Library              | Barack Obama |  534366 |   276223690 | 
-- | 3151617 | President_Barack_Obama                         | Barack Obama |  534366 |   276223690 | 
-- | 3151618 | President_Barack                               | Barack Obama |  534366 |   276223690 | 
-- | 3151619 | Presidant_barack_obama                         | Barack Obama |  534366 |   276223690 | 
-- | 3151620 | Sen._Barack_Obama                              | Barack Obama |  534366 |   276223690 | 
-- | 3151621 | African_American_President                     | Barack Obama |  534366 |   276223690 | 
-- | 3151622 | 44th_president_of_the_united_states_of_america | Barack Obama |  534366 |   276223690 | 
-- | 3151623 | President_Elect_Barack_Obama                   | Barack Obama |  534366 |   276223690 | 
-- | 3151624 | Pres._Obama                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151625 | Obama_II                                       | Barack Obama |  534366 |   276223690 | 
-- | 3151626 | Borack_Obama                                   | Barack Obama |  534366 |   276223690 | 
-- | 3151627 | President_Barack_Hussein_Obama_II              | Barack Obama |  534366 |   276223690 | 
-- | 3151628 | Barry_Soetoro                                  | Barack Obama |  534366 |   276223690 | 
-- | 3151629 | President_Barack_Hussein_Obama                 | Barack Obama |  534366 |   276223690 | 
-- | 3151630 | Obama_44                                       | Barack Obama |  534366 |   276223690 | 
-- | 3151631 | Barack_Obama_Biography                         | Barack Obama |  534366 |   276223690 | 
-- | 3151632 | Barackobama                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151633 | Sen_Obama                                      | Barack Obama |  534366 |   276223690 | 
-- | 3151634 | Brack_obama                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151635 | President_Government                           | Barack Obama |  534366 |   276223690 | 
-- | 3151636 | Barak_h._obama                                 | Barack Obama |  534366 |   276223690 | 
-- | 3151637 | Barak_h_obama                                  | Barack Obama |  534366 |   276223690 | 
-- | 3151638 | Obama_obama                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151639 | President_barack_obama                         | Barack Obama |  534366 |   276223690 | 
-- | 3151640 | Obamism                                        | Barack Obama |  534366 |   276223690 | 
-- | 3151641 | Obamaism                                       | Barack Obama |  534366 |   276223690 | 
-- | 3151642 | BHOII                                          | Barack Obama |  534366 |   276223690 | 
-- | 3151643 | Barack_obma                                    | Barack Obama |  534366 |   276223690 | 
-- | 3151644 | Rocco_Bama                                     | Barack Obama |  534366 |   276223690 | 
-- | 3151645 | Barack_Obama's                                 | Barack Obama |  534366 |   276223690 | 
-- | 3151646 | B._Obama                                       | Barack Obama |  534366 |   276223690 | 
-- +---------+------------------------------------------------+--------------+---------+-------------+
-- 110 rows in set (11.15 sec)






