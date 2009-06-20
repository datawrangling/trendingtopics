#!/usr/bin/env python
# encoding: utf-8
"""
daily_merge.py

Python Hadoop Streaming script to clean article names,
and aggregate hourly log data to daily level for a single day

Created by Peter Skomoroch on 2009-06-10.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys, os, re
import urllib

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

def reducer(args):
  '''
  # hadoop fs -cat finaloutput/part-00010 | head -30000 | tail
  Argument_from_degree	20090613	5
  Argument_from_fallacy	20090613	41
  Argument_from_incredulity	20090613	10

  
  '''
  last_articledate, articledate_sum = None, 0
  for line in sys.stdin:
    try:
      match = articledate_regex.match(line)
      articledate, pageviews = match.groups()
      if last_articledate != articledate and last_articledate is not None:
        articleval, dateval = last_articledate.split('}')
        sys.stdout.write( '\t'.join([articleval, dateval, str(articledate_sum)]) + '\n' )    
        last_articledate, articledate_sum = None, 0  
      last_articledate = articledate
      articledate_sum += int(pageviews) 
    except:
      # skip bad rows
      pass     
  articleval, dateval = last_articledate.split('}')
  sys.stdout.write( '\t'.join([articleval, dateval, str(articledate_sum)]) +'\n' )     
      
if __name__ == "__main__":
  if len(sys.argv) == 1:
    print "Running sample data locally..."
    # Step 1
    os.system('cat smallpagecounts-20090419-020000.txt | '+ \
    ' ./daily_merge.py mapper | LC_ALL=C sort |' + \
    ' ./daily_merge.py reducer > mr_output.txt')
    os.system('head mr_output.txt')    
  elif sys.argv[1] == "mapper":
    mapper(sys.argv[2:])
  elif sys.argv[1] == "reducer":
    reducer(sys.argv[2:])