#!/bin/bash

TODAY=`/bin/date +\%d\%m\%Y`

#Reads the name of the RDS instance from command line (or cron)
AWS_RDS=$1

#The file where the slow query log will be stored
BASE=/home/jose/slow-query-report/$TODAY
SLOWLOG=/$BASE/slowquery.log

#Create folder for the logs of the day
/bin/mkdir $BASE

#Using the AWS CLI to download the MySQL slowquery log parts and then we concatenate it into a huge log
for i in {0..23}; do /usr/local/bin/aws rds download-db-log-file-portion --db-instance-identifier $AWS_RDS --output text --log-file-name slowquery/mysql-slowquery.log.${i} --region eu-west-1 > /$BASE/mysql-slowquery.log.${i}; done
cat /$BASE/mysql-slowquery.log.* > $SLOWLOG

#Run mysqldumpslow to generate 3 reports
# 1. Top 5 queries that returns maximum rows
# 2. Top 5 queries by times found in the slow queries log
# 3. Top 5 queries by execution time

/usr/bin/mysqldumpslow -a -s r -t 5 $SLOWLOG > $BASE/daily-top5-queries-by-rows-$TODAY.txt
/usr/bin/mysqldumpslow -a -s c -t 5 $SLOWLOG > $BASE/daily-top5-queries-by-count-$TODAY.txt
/usr/bin/mysqldumpslow -a -s t -t 5 $SLOWLOG > $BASE/daily-top5-queries-by-time-$TODAY.txt

#The Percona slow query report location
SLOWREPORT=$BASE/daily-pt-query-digest-$TODAY.txt

#Percona query digest (pt-query-digest) location
PT=/usr/bin/pt-query-digest

#Run the tool to get analysis report
$PT $SLOWLOG > $SLOWREPORT

#Compress everything
/bin/tar -cvzf /home/jose/slow-query-report/slow-queries-$TODAY.tar.gz -C $BASE --exclude="mysql-slowquery.*" --exclude="slowquery.log" .


#Send an email and upload the tar.gz to "rds-slowqueries-logs" bucket
#/usr/bin/mailx -s "$SUBJECT" -A /home/jose/slow-query-report/slow-queries-$TODAY.tar.gz $RECIPIENT < /home/jose/slow-query-report/reporte.txt 

/usr/bin/python /home/jose/slow-query-report/send-mail.py
/usr/local/bin/aws s3 cp /home/jose/slow-query-report/slow-queries-$TODAY.tar.gz s3://rds-slowqueries-logs/
 
#Delete log folders after 10 days
find /home/jose/slow-query-report/* -type d -ctime +10 -exec echo rm -rf {} \;
