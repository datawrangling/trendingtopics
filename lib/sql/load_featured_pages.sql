TRUNCATE TABLE new_featured_pages;

LOAD DATA LOCAL INFILE '/mnt/featured_pages.txt'
INTO TABLE new_featured_pages
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id,trend,error);