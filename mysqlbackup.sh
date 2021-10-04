##Creating a simple database backup. The backup is done to a nfs share mounted locally on each database server to a database backup server
##It will send an email once the backup fails or is successful. Backups older than 30 days will be deleted.
# I have used cronjob to do a daily backup.

#!/bin/bash

backupfolder=/"db-backups/$(hostname)"

# Notification email address 
recipient_email=humayunalam@hotmail.com

# MySQL user
user=root

# MySQL password
password=password

# Number of days to store the backup 
keep_day=30

sqlfile=$backupfolder/all-database-$(date +%d-%m-%Y_%H:%M).sql
zipfile=$backupfolder/all-database-$(date +%d-%m-%Y_%H:%M).zip 

#Create a backup folder for host if it does not exist
if [ ! -d "$backupfolder" ]
then
	mkdir $backupfolder/ && echo "Directory created: $backupfolder"
fi


# Create a backup 
sudo mysqldump -u $user -p$password --all-databases > $sqlfile 

if [ $? == 0 ]; then
	echo 'Sql dump created'
else
	(echo "Subject: No backup was created on $(hostname)"; echo "From: sender@domain.com"; echo "To: Me <me@mail.com>"; echo ""; echo "mysqldump return non-zero code") | ssmtp humayunalam@hotmail.com
	exit 
fi 

# Compress backup
zip $zipfile $sqlfile
if [ $? == 0 ]; then
	echo "The backup was successfully compressed"
else
	(echo "Subject: Backup was not compressed on $(hostname)!"; echo "From: sender@domain.com"; echo "To: Me <me@mail.com>"; echo ""; echo "Error compressing backup") | ssmtp humayunalam@hotmail.com
	exit
fi

rm $sqlfile
(echo "Subject: Backup was successfully created on $(hostname)"; echo "From: sender@domain.com"; echo "To: Me <me@mail.com>"; echo ""; echo " File: '$(basename $zipfile)' created.") | ssmtp humayunalam@hotmail.com

# Delete old backups 
find $backupfolder -mtime +$keep_day -delete
