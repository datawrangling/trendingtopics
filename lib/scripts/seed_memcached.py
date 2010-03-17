#!/usr/bin/env python
# encoding: utf-8
"""
seed_memcached.py

quick hack to prepopulate memcached with inital letters for autocomplete

Created by Peter Skomoroch on 2009-06-09.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys
import os
import urllib2
import time

SITE = 'http://www.trendingtopics.org/'


def fetch_url(url):
  response = urllib2.urlopen(url)
  html = response.read()

def fetchpages():
  
  urls = [SITE, SITE+'finance', SITE+'people', SITE+'hourly_trends']
  
  # TODO: read queries and site from a file...
  # autocomplete_template = 'pages/auto_complete_for_search_query?search%5Bquery%5D'
  # prefetch = "abcdefghijklmnopqrstuvwxyz"
  # autocomplete_urls = [SITE + autocomplete_template + x for x in prefetch]  
  # urls.extend(autocomplete_urls)  
  # 
  # search_template = 'pages?search[query]='
  # search_urls = [SITE + search_template + x for x in prefetch] 
  # urls.extend(search_urls)

  for url in urls:
    print "fetching", url
    fetch_url(url)
    time.sleep(1)


def main():
	fetchpages()


if __name__ == '__main__':
	main()

