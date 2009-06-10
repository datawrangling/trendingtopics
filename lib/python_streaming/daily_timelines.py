#!/usr/bin/env python
# encoding: utf-8
"""
daily_trends.py

Python Hadoop Streaming script to clean article names,
aggregate hourly log data to daily level, and estimate
monthly trends  

TODO: refactor out code in common with daily_timelines
TODO: add a real trend algorithm
TODO: emit hourly time series for web app to display

Created by Peter Skomoroch on 2009-06-10.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys, os, re
import urllib

# Exclude pages outside of english wikipedia
wikistats_regex = re.compile('en (.*) ([0-9].*) ([0-9].*)')

# Excludes pages outside of namspace 0 (ns0)
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
  # pages like Facebook#Website really are "Facebook",
  # ignore/strip anything starting at # from pagename
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
  filepath = os.environ["map_input_file"] 
  filename = os.path.split(filepath)[-1]
except KeyError:
  # in testing...
  filename = 'pagecounts-20090419-020000.txt'
      
def mapper1(args):
  '''
  Clean article names, emit "en" subset in following format:
  LongValueSum:article}date\tcount
  '''
  # pull the date and time from the filename
  filename_tokens = filename.split('-')
  (date, time) = filename_tokens[1], filename_tokens[2].split('.')[0] 
  for line in sys.stdin:
      # Read the file, emit 'en' lines with date prepended
      # also un-escape the urls, emit "article}date\t pageviews"
      m = wikistats_regex.match(line)
      if m is not None:
        page, count, bytes = m.groups()
        if is_valid_title(page):
          title = clean_anchors(urllib.unquote_plus(page))
          if len(title) > 0 and title[0] != '#':
            # the following characters are forbidden in wiki page titles
            # so they make good separators: # < > [ ] | { }
            key = '%s}%s' % (title.replace("\t",
            "").replace('}','').replace(' ','_'), date)   
            sys.stdout.write('LongValueSum:%s\t%s\n' % (key, count) )

def reducer1(args):
  '''
  Barack_Obama}20090422  129
  Barack_Obama}20090419  143
  Barack_Obama}20090421  163
  Barack_Obama}20090420  152
  
  '''
  last_articledate, articledate_sum = None, 0
  for line in sys.stdin:
    try:
      match = articledate_regex.match(line)
      articledate, pageviews = match.groups()
      if last_articledate != articledate and last_articledate is not None:
        print '%s\t%s' % (last_articledate, articledate_sum)    
        last_articledate, articledate_sum = None, 0  
      last_articledate = articledate
      articledate_sum += int(pageviews) 
    except:
      # skip bad rows
      pass     
  print '%s\t%s' % (last_articledate, articledate_sum)      
      
      
# Step 2: send rows grouped by article to reducer
def mapper2(args):
  '''    
  Emit "article  date pageview"

  Barack_Obama  20090422 129
  Barack_Obama  20090419 143
  Barack_Obama  20090421 163
  Barack_Obama  20090420 152
  
  '''
  for line in sys.stdin:
    (article_date, pageview) = line.strip().split("\t")
    article, date = article_date.split('}')
    sys.stdout.write('%s\t%s %s\n' % (article, date, pageview))


def calc_trend(dates, pageviews):
  dts,counts = zip( *sorted( zip (dates,pageviews)))
  trend_2 = sum(counts[-15:])
  trend_1 = 1.0*sum(counts[-30:-15])
  monthly_trend = trend_2 - trend_1
  date_str = '[%s]' % ','.join(dts)
  pageview_str = '[%s]' % ','.join(map(str,counts))
  return monthly_trend, date_str, pageview_str

def reducer2(min_days, args):
  '''
  For each article, emit a row containing dates, pagecounts, total_pageviews
  Only emit if number of records >= min_days
  Also emit user rating sum and count for use in Hive Join:

  line = 'Barack_Obama\t[20090419,20090420,' +
   '20090421,20090422]\t[143,152,163,129]\t587'
  
  >>> line = 'Barack_Obama\t[20090420,20090419]\t[993,1134]\t2127'
  >>> line
  'Barack_Obama\t[20090420,20090419]\t[993,1134]\t2127'
  >>> line.split('\t')
  ['Barack_Obama', '[20090420,20090419]', '[993,1134]', '2127']
  
  For using with Rpy and python for regressions:
  http://www2.warwick.ac.uk/fac/sci/moac/currentstudents/peter_cock/python/lin_reg/
  http://www.ats.ucla.edu/stat/R/dae/poissonreg.htm
  http://www.jeremymiles.co.uk/regressionbook/extras/appendix2/R/
  
  >>> import simplejson
  In [59]: foo ='[20090419,20090420,20090421,20090422]'

  In [60]: simplejson.loads(foo)
  Out[60]: [20090419, 20090420, 20090421, 20090422]

  In [61]: dates = simplejson.loads(foo)

  In [62]: dates
  Out[62]: [20090419, 20090420, 20090421, 20090422]
  
  For loading into Ruby arrays from MySQL text strings in the Rails app:
  see http://json.rubyforge.org/
  
  irb(main):001:0> require 'rubygems'
  => true
  irb(main):002:0> require 'json'
  => true
  irb(main):003:0> a = [1,2,3,4,5].to_json
  => "[1,2,3,4,5]"
  irb(main):006:0> foo = '[1,2,3,4,5,6]'
  => "[1,2,3,4,5,6]"
  irb(main):007:0> JSON.parse('[1,2,3,4,5,6]')
  => [1, 2, 3, 4, 5, 6]

  '''
  last_article, dates, pageviews = None, [], []
  total_pageviews = 0
  for line in sys.stdin:
    try:
      (article, date_pageview) = line.strip().split("\t")
      date, pageview = date_pageview.split()
      if last_article != article and last_article is not None:
        if len(dates) >= int(min_days): 
          monthly_trend, date_str, pageview_str = calc_trend(dates, pageviews)  
          sys.stdout.write( "%s\t%s\t%s\t%s\t%s\n" % (last_article, date_str,
           pageview_str, total_pageviews, monthly_trend) )  
        dates, pageviews, total_pageviews = [], [], 0     
      last_article = article
      pageview = int(pageview)
      dates.append(date)
      pageviews.append(pageview)
      total_pageviews += pageview
    except:
      # skip bad rows
      pass  
  # Handle edge case, last row...  
  if len(dates) >= int(min_days):
    monthly_trend, date_str, pageview_str = calc_trend(dates, pageviews)    
    sys.stdout.write( "%s\t%s\t%s\t%s\t%s\n" % (last_article, date_str,
     pageview_str, total_pageviews, monthly_trend) )         
      
      
if __name__ == "__main__":
  if len(sys.argv) == 1:
    print "Running sample data locally..."
    # Step 1
    os.system('cat smallpagecounts-20090419-020000.txt | '+ \
    ' ./daily_pagecounts.py mapper1 | LC_ALL=C sort |' + \
    ' ./daily_pagecounts.py reducer1 > map2_output.txt')
    # Step 2  
    os.system('time cat map2_output.txt |'+ \
    ' ./daily_pagecounts.py mapper2 | LC_ALL=C sort |' + \
    ' ./daily_pagecounts.py reducer2 > part-0000')
    os.system('head part-0000')    
  elif sys.argv[1] == "mapper1":
    mapper1(sys.argv[2:])
  elif sys.argv[1] == "reducer1":
    reducer1(sys.argv[2:])    
  elif sys.argv[1] == "mapper2":
    mapper2(sys.argv[2:])
  elif sys.argv[1] == "reducer2":
    reducer2(sys.argv[2], sys.argv[3:]) 



      