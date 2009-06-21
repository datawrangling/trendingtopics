RENAME TABLE pages TO backup_pages, new_pages TO pages;
RENAME TABLE daily_timelines TO backup_daily_timelines, new_daily_timelines TO daily_timelines;
RENAME TABLE daily_trends TO backup_daily_trends, new_daily_trends TO daily_trends;
RENAME TABLE featured_pages TO backup_featured_pages, new_featured_pages TO featured_pages;