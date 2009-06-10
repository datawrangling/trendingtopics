#!/usr/bin/env python
# encoding: utf-8
"""
daily_trends.py

Python Hadoop Streaming script to to clean article names,
and process hourly wikipedia traffic data for daily trend detection

TODO: refactor out code in common with daily_timelines
TODO: add a real trend algorithm
TODO: emit hourly time series for web app to display

Created by Peter Skomoroch on 2009-06-10.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys, os, re
import urllib
from datetime import date, datetime
from math import log, sqrt

# Exclude pages outside of english wikipedia
wikistats_regex = re.compile('en (.*) ([0-9].*) ([0-9].*)')

# Excludes pages outside of namespace 0 (ns0)
namespace_titles_regex = re.compile('(Media|Special' + 
'|Talk|User|User_talk|Project|Project_talk|File' +
'|File_talk|MediaWiki|MediaWiki_talk|Template' +
'|Template_talk|Help|Help_talk|Category' +
'|Category_talk|Portal|Wikipedia|Wikipedia_talk)\:(.*)')

# More exclusions
first_letter_is_lower_regex = re.compile('([a-z])(.*)')
image_file_regex = re.compile('(.*).(jpg|gif|png|JPG|GIF|PNG|txt|ico)')

# Exclude mediawiki boilerplate
blacklist = [
'404_error/',
'Main_Page',
'Hypertext_Transfer_Protocol',
'Favicon.ico',
'Search'
]

def clean_anchors(page):
  """
  pages like Facebook#Website really are "Facebook",
  ignore/strip anything starting at # from pagename
  """ 
  anchor = page.find('#')
  if anchor > -1:
    page = page[0:anchor]
  return page  

def is_valid_title(title):
  is_outside_namespace_zero = namespace_titles_regex.match(title)
  if is_outside_namespace_zero is not None:
    return False
  islowercase = first_letter_is_lower_regex.match(title)
  if islowercase is not None:
    return False
  is_image_file = image_file_regex.match(title)
  if is_image_file:
    return False  
  has_spaces = title.find(' ')
  if has_spaces > -1:
    return False
  if title in blacklist:
    return False   
  return True  

try:
  # See if we are running on Hadoop cluster
  filepath = os.environ["map_input_file"] 
  filename = os.path.split(filepath)[-1]
except KeyError:
  # sample file for use in testing...
  filename = 'pagecounts-20090419-020000.txt'
  
def to_date(rawdate):
	rawdate = str(rawdate)
	year = int(rawdate[0:4])
	month = int(rawdate[4:6])
	day = int(rawdate[6:8])
	dateval = date(year, month, day)
	return dateval

def to_hour(rawdate):
	rawdate = str(rawdate)
	hour = int(rawdate[8:10])	
	return hour

def trendvalue(datetimes, pageviews):
  '''
  Dead simple trend algorithm used for demo
  Only needs the last 10 days of data
  '''
  # Today's pageviews...
  total_pageviews = sum(pageviews)
  y2 = sum(pageviews[-48:])
  # Yesterdays pageviews...
  y1 = sum(pageviews[-96:-48])
  # Simple baseline trend algorithm
  slope = (y2 - y1)
  trend = slope  * (1.0 + log(1.0 +int(total_pageviews)))
  error = 1.0/sqrt(int(total_pageviews))  
  return trend, error
      
def calc_trend(dates, pageviews):
  """
  Wrapper for trend estimation.
  When we reach the last hourly record, we sort by date.
  """
  dtms,counts = zip( *sorted( zip (dates,pageviews)))
  # exclude the last 24 data points... used to estimate trend
  # You can use Rpy to fit regression model to historical data
  # or do some other processing here...
  try:
    daily_trend, error = trendvalue(dtms, counts)
  except:
    # skip bad rows
    daily_trend = 0   
    error = 0   
  # params = ' '
  # Also return last 48 hours of hourly pageviews..  
  # datetime_str = '[%s]' % ','.join(dtms)
  # pageview_str = '[%s]' % ','.join(map(str,counts))
  # return daily_trend, params, datetime_str, pageview_str      
  return daily_trend, error    
      
def mapper(args):
  """
  - Pull the date and time from the filename
  - Clean article names
  - Emit "en" subset formated as: article\tYYYYMMDD count
  """ 
  filename_tokens = filename.split('-')
  (date, time) = filename_tokens[1], filename_tokens[2].split('.')[0] 
  for line in sys.stdin:
      m = wikistats_regex.match(line)
      if m is not None:
        page, count, bytes = m.groups()
        if is_valid_title(page):
          title = clean_anchors(urllib.unquote_plus(page))
          if len(title) > 0 and title[0] != '#':
            article = title.replace("\t","").replace("}","").replace(' ','_') 
            sys.stdout.write('%s\t%s %s\n' % (article, date, count))

def reducer(min_days, args):
  """
  Hourly data arrives grouped by article
  in format: article\tYYYYMMDD count
  
  We include a cutoff parameter to exclude
  articles with insufficient data from 
  consideration.
  
  Run a trend algorithm and return values, 
  tab delimited parameters:
  "last_article, daily_trend, error"
  """
  last_article, dates, pageviews = None, [], []
  for line in sys.stdin:
    try:
      (article, date_pageview) = line.strip().split("\t")
      dateval, pageview = date_pageview.split()
      if last_article != article and last_article is not None:
        if len(dates) >= int(min_days):
          daily_trend, error = calc_trend(dates, pageviews)
          sys.stdout.write( "%s\t%s\t%s\n" % (last_article, daily_trend, error) )            
        dates, pageviews = [], []  
      last_article = article
      dates.append(dateval) 
      pageviews.append(int(pageview))
    except:
      # skip bad rows
      pass  
  # Handle edge case, last row...  
  if len(dates) >= int(min_days):
    daily_trend, error = calc_trend(dates, pageviews)
    sys.stdout.write( "%s\t%s\t%s\n" % (last_article, daily_trend, error) )    
      
      
if __name__ == "__main__":
  if len(sys.argv) == 1:
    print "Running sample data locally..."
    os.system('cat smallpagecounts-20090419-020000.txt | '+ \
    ' ./daily_pagecounts.py mapper | LC_ALL=C sort |' + \
    ' ./daily_pagecounts.py reducer 504 > hourly_output.txt')
    os.system('head part-0000')    
  elif sys.argv[1] == "mapper":
    mapper(sys.argv[2:])
  elif sys.argv[1] == "reducer":
    reducer(sys.argv[2], sys.argv[3:])