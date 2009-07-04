#!/usr/bin/env python
# encoding: utf-8
"""
hourly_timelines.py

Python Hadoop Streaming script to to clean article names,
and emit hourly wikipedia traffic data in json format

Example command line usage for 2 hourly files:

cat pagecounts-2009052* | /mnt/app/current/lib/python_streaming/hourly_timelines.py mapper | LC_ALL=C sort | /mnt/app/current/lib/python_streaming/hourly_timelines.py reducer 2 >foo_out.txt

# grep Barack foo_out.txt | head
2008_Barack_Obama_assassination_scare_in_Denver	[2009041902,2009041902]	[1,2]
Barack_H_Obama	[2009041902,2009041902]	[1,3]
Barack_H_Obama_Jr.	[2009041902,2009041902]	[1,2]
Barack_Hussein_Obama,_Junior	[2009041902,2009041902]	[1,2]
Barack_Obama	[2009041902,2009041902,2009041902]	[1,630,701]
Barack_Obama's_first_100_days	[2009041902,2009041902]	[2,2]
Barack_Obama,_Sr.	[2009041902,2009041902]	[10,20]
Barack_Obama_"HOPE"_poster	[2009041902,2009041902]	[2,3]
Barack_Obama_"Hope"_poster	[2009041902,2009041902]	[13,3]
Barack_Obama_(comic_character)	[2009041902,2009041902]	[1,1]


Created by Peter Skomoroch on 2009-06-10.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys, os, re
import urllib
from collections import defaultdict

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
            datehour = date + hour  
            sys.stdout.write('%s\t%s %s\n' % (key, datehour, count) )

def group_data(pageviews):
  #TODO: zeros for missing datetimes
  dts = pageviews.keys()
  dts.sort()
  counts = [pageviews[x] for x in dts]
  date_str = '[%s]' % ','.join(dts)
  pageview_str = '[%s]' % ','.join(map(str,counts))
  return date_str, pageview_str

def reducer(min_days, args):
  '''
  For each article, emit a row containing sorted datetimes, pagecounts
  Only emit if number of records >= min_days

  line = 'Barack_Obama\t[2009041901,2009042002,' +
   '2009042123,2009042221]\t[143,152,163,129]\n'
  
  use defaultdict:
    
  >>> from collections import defaultdict
  >>> pageviews=defaultdict(int)
  >>> pageviews['foo'] += 1
  >>> pageviews['foo']
  1
  
  In the case where multiple records map to same url we need to
  sum counts using a defaultdict
  
  en 2nd_Infantry_Division_(United_States) 10 295759
  en 2nd_Infantry_Division_%28United_States%29 2 33234

  '''
  last_article = None
  pageviews=defaultdict(int)
  for line in sys.stdin:
    try:
      (article, date_pageview) = line.strip().split("\t")
      date, pageview = date_pageview.split()
      if last_article != article and last_article is not None:
        if len(pageviews) >= int(min_days): 
          date_str, pageview_str = group_data(pageviews)  
          sys.stdout.write( "%s\t%s\t%s\n" % (last_article, date_str, pageview_str))
        pageviews=defaultdict(int)
      last_article = article
      pageviews[date] += int(pageview)
    except:
      # skip bad rows
      pass  
  # Handle edge case, last row...  
  if len(pageviews) >= int(min_days):
    date_str, pageview_str = group_data(pageviews)     
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
