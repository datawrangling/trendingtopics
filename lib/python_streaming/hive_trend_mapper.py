#!/usr/bin/env python
# encoding: utf-8
"""
hive_trend_mapper.py

Python Hadoop Streaming script called by Hive
in daily run - calculates simple baseline
monthly & daily trends for articles

Created by Peter Skomoroch on 2009-06-10.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys, os, re
from math import log, sqrt
import simplejson

def calc_monthly_trend(dates, pageviews):
  dts,counts = zip( *sorted( zip (dates,pageviews)))
  trend_2 = sum(counts[-15:])
  trend_1 = 1.0*sum(counts[-30:-15])
  monthly_trend = trend_2 - trend_1
  return monthly_trend
  
def calc_daily_trend(dates, pageviews, total_pageviews):
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
  dates = simplejson.loads(dates)
  pageviews = simplejson.loads(pageviews)  
  try:
    monthly_trend = calc_monthly_trend(dates, pageviews)
    daily_trend, error = calc_daily_trend(dates, pageviews, total_pageviews)
  except:
    # skip bad rows
    monthly_trend = 0 
    daily_trend = 0   
    error = 0        
  sys.stdout.write('%s\t%s\t%s\t%s\t%s\n' % (page_id, total_pageviews, monthly_trend, daily_trend, error))