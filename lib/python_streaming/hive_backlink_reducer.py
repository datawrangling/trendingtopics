#!/usr/bin/env python
# encoding: utf-8
"""
hive_backlink_reducer.py

Python Hadoop Streaming script called by Hive
in daily run - emits backlinks by page

Created by Peter Skomoroch on 2009-06-10.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys, os

def top_backlinks(backlinks, daily_trends):
  # return top 10 backlinks based on trend
  trends,links = zip( *sorted( zip (daily_trends,backlinks)))
  backlink_str = '[%s]' % ','.join(links[-10:])
  return backlink_str

#  For each page, emit backlink "postings" sorted by trend desc
last_page, backlinks, daily_trends = None, [], []
for line in sys.stdin:
  (page, backlink, daily_trend) = line.strip().split("\t")
  if last_page != page and last_page is not None:
    backlink_string = top_backlinks(backlinks, daily_trends)
    print "%s\t%s" % (last_page, backlink_string)    
    backlinks = []
    daily_trends = []    
  last_page = page
  backlinks.append(backlink)
  daily_trends.append(daily_trend)
backlink_string = top_backlinks(backlinks, daily_trends)       
print "%s\t%s" % (last_page, backlink_string)