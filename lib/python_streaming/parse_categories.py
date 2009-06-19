#!/usr/bin/env python
# encoding: utf-8
"""
parse_categories.py

convert stupid sql insert format from wikipedia dump into
a tab delimited text file

Created by Peter Skomoroch on 2009-06-18.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys, os, re


insert_regex = re.compile('''INSERT INTO \`categorylinks\` VALUES (.*)\;''')
row_regex = re.compile("""(.*),'(.*)','(.*)',(.*)""")
	  
for line in sys.stdin:
  match = insert_regex.match(line.strip())
  if match is not None:
    data = match.groups(0)[0]
    rows = data[1:-1].split("),(")
    for row in rows:
      row_match = row_regex.match(row)
      if row_match is not None:
        # >>> row_match.groups()
        # (305,'People_of_the_Trojan_War','Achilles',20090301193903)
        # page_id, category_url
        page_id, category_url = row_match.groups()[0], row_match.groups()[1]
        sys.stdout.write('%s\t%s\n' % (page_id, category_url))
      


