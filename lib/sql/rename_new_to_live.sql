RENAME TABLE pages TO backup_pages, new_pages TO pages;
RENAME TABLE people TO backup_people, new_people TO people;
RENAME TABLE companies TO backup_companies, new_companies TO companies;
RENAME TABLE daily_timelines TO backup_daily_timelines, new_daily_timelines TO daily_timelines;
RENAME TABLE hourly_timelines TO backup_hourly_timelines, new_hourly_timelines TO hourly_timelines;
RENAME TABLE featured_pages TO backup_featured_pages, new_featured_pages TO featured_pages;