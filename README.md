# guerrilla-backup
Guerrilla backup system

```
sudo -i
cd /opt/
git clone 'https://github.com/pmoghadam/guerrilla-backup.git'
mkdir -p /srv/backups /srv/delete
cd guerrilla-backup
ln -sfn /srv/backups backups
ln -sfn /srv/delete delete
```

* Copy project to /opt/guerrilla-backup/
* Create symlinks for /opt/guerrilla-backup/backups and /opt/guerrilla-backup/delete (both should be in the same partition)
* Create host files in hosts dir (example: docs/hosts.example)
* Read all files in scripts dir and make changes if needed
* Change /etc/crontab (example: docs/crontab.example)
