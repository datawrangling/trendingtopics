-- load_history.sql
--
-- This is run after the initial daily timeline job to populate 
-- historical daily timelines and page metadata.  For 8 months of data:
--
-- $ time mysql -u root trendingtopics_production <  /mnt/app/current/lib/sql/load_history.sql
-- real 49m56.652s
-- user 0m1.512s
-- sys  0m9.237s

-- load entity metadata tables...
TRUNCATE TABLE people;
TRUNCATE TABLE companies;

LOAD DATA LOCAL INFILE '/mnt/Living_people.txt'
INTO TABLE people
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id);
  
LOAD DATA LOCAL INFILE '/mnt/Companies_listed_on_the_New_York_Stock_Exchange.txt'
INTO TABLE companies
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id);

CALL dropindex('people', 'people_page_index');
CALL dropindex('companies', 'companies_page_index');
create index companies_page_index on companies (page_id); 
create index people_page_index on people (page_id); 
  
-- load data tables
TRUNCATE TABLE new_pages;
TRUNCATE TABLE new_daily_timelines;

DELIMITER $$

DROP PROCEDURE IF EXISTS `dropindex` $$
CREATE PROCEDURE `dropindex` (tblName VARCHAR(64), ndxName VARCHAR(64))
BEGIN

    DECLARE IndexColumnCount INT;
    DECLARE SQLStatement VARCHAR(256);

    SELECT COUNT(1) INTO IndexColumnCount
    FROM information_schema.statistics
    WHERE table_name = tblName
    AND index_name = ndxName;

    IF IndexColumnCount > 0 THEN
        SET SQLStatement = CONCAT('ALTER TABLE `',tblName,'` DROP INDEX `',ndxName,'`');
        SET @SQLStmt = SQLStatement;
        PREPARE s FROM @SQLStmt;
        EXECUTE s;
        DEALLOCATE PREPARE s;
    END IF;

END $$

DELIMITER ;

CALL dropindex('new_pages', 'new_pages_autocomp_index');
CALL dropindex('new_pages', 'new_pages_trend_index');
CALL dropindex('new_daily_timelines', 'new_timeline_pageid_index');
CALL dropindex('new_pages', 'pages_autocomp_index');
CALL dropindex('new_pages', 'pages_id_index');
-- CALL dropindex('new_pages', 'pages_autocomp_trend_index');
CALL dropindex('new_pages', 'pages_trend_index');
CALL dropindex('new_daily_timelines', 'timeline_pageid_index');


set foreign_key_checks=0; 
set sql_log_bin=0; 
set unique_checks=0;

ALTER TABLE new_pages DISABLE KEYS;
ALTER TABLE new_daily_timelines DISABLE KEYS;

LOAD DATA LOCAL INFILE '/mnt/pages.txt'
INTO TABLE new_pages
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(id, url, title, page_latest, total_pageviews, monthly_trend);

-- Query OK, 2783939 rows affected (9 min 12.61 sec)
-- Records: 2783939  Deleted: 0  Skipped: 0  Warnings: 0

LOAD DATA LOCAL INFILE '/mnt/daily_timelines.txt'
INTO TABLE new_daily_timelines
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id, dates, pageviews, total_pageviews);

-- Query OK, 2783939 rows affected (3 min 56.88 sec)
-- Records: 2783939  Deleted: 0  Skipped: 0  Warnings: 0

ALTER TABLE new_pages ENABLE KEYS;
ALTER TABLE new_daily_timelines ENABLE KEYS;

set foreign_key_checks=1; 
set unique_checks=1;


-- for autocomplete 'like' query
create index pages_autocomp_index on new_pages (title(64), monthly_trend);
-- Query OK, 2783939 rows affected (6 min 20.95 sec)
-- Records: 2783939  Duplicates: 0  Warnings: 0

-- for finance and people queries:

create index pages_id_index on new_pages (id);
--Query OK, 2804203 rows affected (9 min 57.82 sec)
  
create index pages_url_index on new_pages(url(64));
--Query OK, 2804203 rows affected (12 min 40.48 sec)
  


-- create index pages_autocomp_trend_index on new_pages (title(64), monthly_trend);
-- Query OK, 2783939 rows affected (6 min 20.95 sec)
-- Records: 2783939  Duplicates: 0  Warnings: 0


-- for main pagination
create index pages_trend_index on new_pages (monthly_trend);
-- Query OK, 2783939 rows affected (1 min 25.65 sec)
-- Records: 2783939  Duplicates: 0  Warnings: 0

-- for sparklines
create index timeline_pageid_index on new_daily_timelines (page_id);
-- Query OK, 2804057 rows affected (22 min 33.80 sec)
-- Records: 2804057  Duplicates: 0  Warnings: 0




