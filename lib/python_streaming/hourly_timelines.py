#!/usr/bin/env python
# encoding: utf-8
"""
hourly_timelines.py

Python Hadoop Streaming script to to clean article names,
and emit hourly wikipedia traffic data in json format

Created by Peter Skomoroch on 2009-06-10.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys, os, re
import urllib
from datetime import date, datetime

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

# Exclude Mediawiki boilerplate
blacklist = [
'404_error/',
'Main_Page',
'Hypertext_Transfer_Protocol',
'Favicon.ico',
'Search'
]

articledate_regex = re.compile('LongValueSum:(.*)\t([0-9].*)')


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
      
def mapper(args):
  '''
  Clean article names, emit "en" subset in following format:
  article\tdatetime count
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
            key = title.replace("\t","").replace(' ','_')
            #we only keep the hour...
            hour=time[0:2]
            datetime = date + hour  
            sys.stdout.write('%s\t%s %s\n' % (key, datetime, count) )

def group_data(dates, pageviews):
  dts,counts = zip( *sorted( zip (dates,pageviews)))
  date_str = '[%s]' % ','.join(dts)
  pageview_str = '[%s]' % ','.join(map(str,counts))
  return date_str, pageview_str

def reducer(min_days, args):
  '''
  For each article, emit a row containing sorted datetimes, pagecounts
  Only emit if number of records >= min_days

  line = 'Barack_Obama\t[2009041901,2009042002,' +
   '2009042123,2009042221]\t[143,152,163,129]\n'
  
  '''
  last_article, dates, pageviews = None, [], []
  for line in sys.stdin:
    try:
      (article, date_pageview) = line.strip().split("\t")
      date, pageview = date_pageview.split()
      if last_article != article and last_article is not None:
        if len(dates) >= int(min_days): 
          date_str, pageview_str = group_data(dates, pageviews)  
          sys.stdout.write( "%s\t%s\t%s\n" % (last_article, date_str, pageview_str))
        dates, pageviews = [], []
      last_article = article
      dates.append(date)
      pageviews.append(pageview)
    except:
      # skip bad rows
      pass  
  # Handle edge case, last row...  
  if len(dates) >= int(min_days):
    date_str, pageview_str = group_data(dates, pageviews)     
    sys.stdout.write( "%s\t%s\t%s\n" % (last_article, date_str, pageview_str))        


if __name__ == "__main__":
  if len(sys.argv) == 1:
    print "Running sample data locally..."
    # Step 1
    os.system('cat smallpagecounts-20090419-020000.txt | '+ \
    ' ./hourly_timelines.py mapper | LC_ALL=C sort |' + \
    ' ./hourly_timelines.py reducer 10 > part-0000')
    os.system('head part-0000')    
  elif sys.argv[1] == "mapper":
    mapper(sys.argv[2:])
  elif sys.argv[1] == "reducer":
    reducer(sys.argv[2], sys.argv[3:])
