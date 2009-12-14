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

def top_backlinks(backlinks, scores):
  # return top 10 backlinks based on score metric (trend)
  scorevals,links = zip( *sorted( zip (scores,backlinks)))
  toplinks = list(links)
  toplinks.reverse()
  backlink_str = '[%s]' % ','.join(toplinks[:10])
  return backlink_str

#  For each page, emit backlinks sorted by score desc
last_page, backlinks, scores = None, [], []
for line in sys.stdin:
  try:
    (page, backlink, score) = line.strip().split("\t")
    if last_page != page and last_page is not None:
      backlink_string = top_backlinks(backlinks, scores)
      print "%s\t%s" % (last_page, backlink_string)    
      backlinks = []
      scores = []    
    last_page = page
    backlinks.append(backlink)
    scores.append(float(score))
  except:
    pass  
backlink_string = top_backlinks(backlinks, scores)       
print "%s\t%s" % (last_page, backlink_string)