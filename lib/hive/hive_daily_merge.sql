# 1. creates tables

# 2. imports raw_daily_pagecounts from streaming job hdfs dir.

# 3. imports old pages, daily_timelines, redirect_lookup files from filesystem

# 4. normalizes python streaming output table "raw_daily_pagecounts" with page_id

# 5. merges old daily_timelines with new, inserts into "new_daily_timelines"

# 6. run "monthly trend" python streaming script from Hive, calc 30 day trend and total pageviews
#  insert to new_pages Hive table.

# 7. run daily_trend python streaming script from Hive, calc daily trend for all articles
#  insert to new_daily_trends Hive table