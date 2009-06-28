TRUNCATE TABLE new_featured_pages;
ALTER TABLE new_featured_pages DISABLE KEYS;

LOAD DATA LOCAL INFILE '/mnt/featured_pages.txt'
INTO TABLE new_featured_pages
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(page_id);


ALTER TABLE new_featured_pages ENABLE KEYS;