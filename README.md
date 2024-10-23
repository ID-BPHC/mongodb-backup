# mongodb-backup
Takes mongodump of all DBs of server everyday at 7am

Uses cronjob : `0 7 * * * /backups/mongo-backups.sh`
