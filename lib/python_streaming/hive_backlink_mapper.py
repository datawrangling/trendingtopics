#!/usr/bin/env python
# encoding: utf-8
"""
hive_backlink_mapper.py

Python Hadoop Streaming script called by Hive
in daily run - emits backlinks by page

Created by Peter Skomoroch on 2009-06-10.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys, os

for line in sys.stdin:
  page_id, bl_title, daily_trend = line.strip().split("\t")
  sys.stdout.write('%s\t%s\t%s\n' % (page_id, bl_title, daily_trend))