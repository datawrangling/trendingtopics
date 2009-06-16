#!/usr/bin/env python
# encoding: utf-8
"""
hadoop_mailer.py

Customize this for your own site...

Usage:

python hadoop_mailer.py run_daily_timelines.sh starting trendingtopics.org pete@datawrangling.com 
python hadoop_mailer.py run_daily_timelines.sh complete trendingtopics.org pete@datawrangling.com

Created by Peter Skomoroch on 2009-06-13.
Copyright (c) 2009 Data Wrangling LLC. All rights reserved.
"""

import sys
import os
import smtplib
import datetime
import string

def main(argv=None):
  if argv is None:
    argv = sys.argv
  SERVER = "localhost"
  FROM = "hadoop@%s" % argv[3]
  TO = ["%s" % argv[4]] # must be a list
  SUBJECT = "Hadoop Job %s is %s" % (argv[1], argv[2])

  TEXT = "The job %s is %s" % (argv[1], argv[2])
  TEXT = TEXT + '\nTime is %s\n' % datetime.datetime.now()  

  if argv[2] == 'complete' and argv[1] == 'run_daily_timelines.sh':
    stdout_handle = os.popen('ls -lh /mnt/trendsdb.tar.gz', "r")
    mysql_text = stdout_handle.read()
    mysql_text = "\nNumber of lines in new_pages: \n" + mysql_text +"\n"  
    TEXT = TEXT + mysql_text  
    TEXT = TEXT + "Terminate Hadoop cluster with: \ncloudera $ bin/hadoop-ec2 terminate-cluster\n\n my-hadoop-cluster\nReady for MySQL load, to start the load run:\ntrendingtopics $ cap load_staging_tables"

  # Prepare actual message  
  message = string.join((
      "From: %s" % FROM,
      "To: %s" % ", ".join(TO),
      "Subject: %s" % SUBJECT,
      "",
      TEXT
      ), "\r\n")
  
  # Send the mail
  server = smtplib.SMTP(SERVER)
  server.set_debuglevel(1)  
  server.sendmail(FROM, TO, message)
  server.quit()


if __name__ == "__main__":
  sys.exit(main())

