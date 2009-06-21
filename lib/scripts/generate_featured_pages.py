#!/usr/bin/env python
# encoding: utf-8
"""
generate_featured_pages.py

Created by Peter Skomoroch on 2009-06-20.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys
import getopt
import urllib
import urllib2
from BeautifulSoup import BeautifulSoup
import datetime
import MySQLdb

# TODO pass as parameters
MYSERVER = 'trendingtopics.org'
DBNAME = 'trendingtopics_production'
USER = 'root'
PASSWD = ''

help_message = '''
Dynamically creates a blacklist of pageids based on given date by removing
wikipedia featured articles and "on this day" references from the main page.  

Usage:

$ python generate_featured_pages.py -d 20090618 > featured_pages.txt

'''

class Usage(Exception):
  def __init__(self, msg):
    self.msg = msg
    
def pageid(title):
  # quick hack to get page_id from db, rails app might not be running yet
  try:
    conn = MySQLdb.connect(db=DBNAME, user=USER, passwd=PASSWD)  
    cursor = conn.cursor()
    cursor.execute("""SELECT id FROM pages
             WHERE title = '%s';""" % title)
    row = cursor.fetchone()
    pageid = row[0]         
    cursor.close()
    conn.close() 
  except:
    pageid = 1  
  return pageid   
    
def get_titles(soup):
  """
  Extract wikipedia links from soup instance
  """
  links = [x['href']  for x in soup.findAll('a') if x['href'][0:5]=='/wiki']
  ns_zero_urls = [x.replace('/wiki/','') for x in links if x.find(':') == -1]
  titles = [urllib.unquote_plus(x.replace('_', ' ')) for x in ns_zero_urls]
  return titles   

def soupify_url(url):
  opener = urllib2.build_opener()
  opener.addheaders = [('User-agent', 'TrendingTopics/0.1')]
  page = opener.open( url ).read()
  soup = BeautifulSoup(page)
  return soup

def featured_pages(date):
  base = 'http://en.wikipedia.org/wiki/Wikipedia:Today%27s_featured_article/' 
  # get previous 3 days of featured articles...
  url = base + date.strftime("%B_%d,_%Y")
  soup = soupify_url(url)
  div = soup.findAll(id="bodyContent")
  titles = get_titles(div[0])
  return titles
  
def featured_pictures(date):
  base = 'http://en.wikipedia.org/wiki/Template:POTD/'
  url = base + date.strftime("%Y-%m-%d")
  soup = soupify_url(url)
  table = soup.findAll(cellspacing="5")
  titles = get_titles(table[0])  
  return titles
  
def date_pages(date):
  return [date.strftime("%B %d")]
  
def anniversaries(date):
  base = 'http://en.wikipedia.org/wiki/Wikipedia:Selected_anniversaries/'
  url = base + date.strftime("%B_%d")
  soup = soupify_url(url)
  div = soup.findAll(id="bodyContent")
  titles = get_titles(div[0])
  return titles  
  
def titles_for_date(date):
  titles = featured_pages(date) 
  titles.extend(featured_pictures(date))
  titles.extend(date_pages(date))
  titles.extend(anniversaries(date))
  return titles  

def main(argv=None):
  if argv is None:
    argv = sys.argv
  try:
    try:
      opts, args = getopt.getopt(argv[1:], "hd:v", ["help", "date="])
    except getopt.error, msg:
      raise Usage(msg)
  
    # option processing
    for option, value in opts:
      if option == "-v":
        verbose = True
      if option in ("-h", "--help"):
        raise Usage(help_message)
      if option in ("-d", "--date"):
        datestr = value
        maxdate = datetime.date(int(datestr[0:4]), int(datestr[4:6]), int(datestr[6:8]))
        
    # find urls recently featured on main page of wikipedia
    titles = titles_for_date(maxdate)
    titles.extend(titles_for_date(maxdate - datetime.timedelta(1)))
    titles.extend(titles_for_date(maxdate - datetime.timedelta(2)))
    
    # generate blacklist of page_ids:
    pageids = [pageid(x) for x in set(titles)]
    for x in pageids:
      try:
        sys.stdout.write('%s\n' % x)
      except:
        pass  
  
  except Usage, err:
    print >> sys.stderr, sys.argv[0].split("/")[-1] + ": " + str(err.msg)
    print >> sys.stderr, "\t for help use --help"
    return 2


if __name__ == "__main__":
  sys.exit(main())
