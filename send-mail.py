'''This script sends a daily email with SES and the RDS slow queries'''

from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart

import boto.ses
import time

msg = MIMEMultipart()
today = time.strftime("%d/%m/%Y")
todaydate = time.strftime("%d%m%Y");
report = 'slow-queries-%s.tar.gz' % todaydate
recipients = ['mail@mail.com']

msg['Subject'] = 'Slow Query Report  - %s' % today
msg['From'] = 'mail@mail.com'

# message preamble
msg.preamble = 'Slow Query Report\n'

# message body
part = MIMEText(open('/home/jose/slow-query-report/reporte.txt', 'r').read())
msg.attach(part)

# attachment
part = MIMEApplication(open('/home/jose/slow-query-report/slow-queries-%s.tar.gz' % todaydate, 'rb').read())
part.add_header('Content-Disposition', 'attachment', filename=report) 
msg.attach(part)

# connect to SES
connection = boto.ses.connect_to_region('eu-west-1', aws_access_key_id='YOUR_ACCESS_KEY_ID'
    , aws_secret_access_key='YOUR_SECRET_ACCESS_KEY')

# and send the message

for recipient in recipients:
	print recipient
	msg['To'] = recipient
	result = connection.send_raw_email(msg.as_string()
	    , source=msg['From']
	    , destinations=recipient)
