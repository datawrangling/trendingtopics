#!/usr/bin/env python
# encoding: utf-8
"""
hive_daily_trend_mapper.py

Python Hadoop Streaming script called by Hive
in daily run - calculates simple baseline
daily trend for "Rising" topics

Created by Peter Skomoroch on 2009-06-10.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys, os, re
from datetime import date, datetime
from math import log, sqrt

def trendvalue(dates, pageviews, total_pageviews):
  '''
  Dead simple trend algorithm used for demo
  Only needs the last 10 days of data
  '''
  # ~Today's pageviews...
  y2 = sum(pageviews[-2:])
  # ~Yesterdays pageviews...
  y1 = sum(pageviews[-4:-2])
  # Simple baseline trend algorithm
  slope = (y2 - y1)
  trend = slope  * (1.0 + log(1.0 +int(total_pageviews)))
  error = 1.0/sqrt(int(total_pageviews))  
  return trend, error
  
for line in sys.stdin:
  (page_id, dates, pageviews, total_pageviews) = line.strip().split("\t")
  try:
    daily_trend, error = trendvalue(dates, pageviews, total_pageviews)
  except:
    # skip bad rows
    daily_trend = 0   
    error = 0  
  sys.stdout.write('%s\t%s\t%s\n' % (page_id, daily_trend, error))
