# mongodb-backup
Takes mongodump of all DBs of server everyday at 3am

Uses cronjob : `0 3 * * * /backups/mongo-backups.sh`

To make changes to the script:
`sudo nano /backups/mongo-backups.sh`

To make changes to cronjob: </br>
Run `sudo crontab -e` to open the editor and then make changes accordingly. </br>
<i>Note: Mess with this only if you know what you're doing!</i>
