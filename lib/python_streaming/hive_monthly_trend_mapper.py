#!/usr/bin/env python
# encoding: utf-8
"""
hive_monthly_trend_mapper.py

Python Hadoop Streaming script called by Hive
in daily run - calculates simple baseline
monthly trend for "Biggest Movers"

Created by Peter Skomoroch on 2009-06-10.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys, os, re
import simplejson

def calc_trend(dates, pageviews):
  dts,counts = zip( *sorted( zip (dates,pageviews)))
  trend_2 = sum(counts[-15:])
  trend_1 = 1.0*sum(counts[-30:-15])
  monthly_trend = trend_2 - trend_1
  return monthly_trend

for line in sys.stdin:
  (page_id, dates, pageviews, total_pageviews) = line.strip().split("\t")
  dates = simplejson.loads(dates)
  pageviews = simplejson.loads(pageviews)  
  try:
    monthly_trend = calc_trend(dates, pageviews)
  except:
    # skip bad rows
    monthly_trend = 0     
  sys.stdout.write('%s\t%s\t%s\n' % (page_id, total_pageviews, monthly_trend))
