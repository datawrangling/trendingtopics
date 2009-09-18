#!/usr/bin/env python
# encoding: utf-8
"""
parse_links.py

convert mediawiki sql insert format from wikipedia link dump into
a tab delimited text file ready for distributed hadoop processing

to run on a single machine:

# cat enwiki-20090618-pagelinks.sql | ./parse_links.py > links.txt

sample output: 

12	Anarchism_and_Other_Essays
12	Anarchism_and_anarcho-capitalism
12	Anarchism_and_animal_rights
12	Anarchism_and_capitalism


Created by Peter Skomoroch on 2009-06-18.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys, os, re

insert_regex = re.compile('''INSERT INTO \`pagelinks\` VALUES (.*)\;''')
row_regex = re.compile("""(.*),(.*),'(.*)'""")
	  
for line in sys.stdin:
  match = insert_regex.match(line.strip())
  if match is not None:
    data = match.groups(0)[0]
    rows = data[1:-1].split("),(")
    for row in rows:
      row_match = row_regex.match(row)
      if row_match is not None:
        # >>> row_match.groups()
        # (12,0,'Anti-statism')
        # # page_id, pl_namespace, pl_title
        if row_match.groups()[1] == '0':
          page_id, pl_title = row_match.groups()[0], row_match.groups()[2]
          sys.stdout.write('%s\t%s\n' % (page_id, pl_title))