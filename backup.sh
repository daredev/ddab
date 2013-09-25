#!/bin/bash
if [ $# -gt 1 ] 
then
	echo "Improper script usage, should be: `basename $0` or `basename $0` TARGET_DIR"
else
	if [ $# = 1 ]
	then
		target=$1
	elif [ $# = 0 ]
	then
		target=`pwd`
	fi
	dir_prefix="backup"
	date=`date +%Y-%m-%d`
	dir=$dir_prefix-$date
	target_path=$target/$dir
	if [ -d $target_path ]
	then
		echo "Target directory exists... Deleting..."
		rm -rf $target_path
	else
		echo "Creating target directory and subdirectories"
	fi
		mkdir -p $target_path/configs/nginx/
		mkdir -p $target_path/configs/bind9/
		mkdir -p $target_path/mysql/
		mkdir -p $target_path/www/
	cd $target_path
	echo "--#1--=====Bind9=====-----"
	cp /etc/bind/named.conf $target_path/configs/bind9/
	cp /etc/bind/named.conf.local $target_path/configs/bind9/	
	sudo cp -v `cat /etc/bind/named.conf.local | grep file | awk -F\" '{ print $2 }'` $target_path/configs/bind9/
	
	echo "--#2--=====NginX=====-----"
	cp -v /etc/nginx/nginx.conf $target_path/configs/nginx/
	cp -r /etc/nginx/sites-available $target_path/configs/nginx/
	cp -r /etc/nginx/sites-enabled $target_path/configs/nginx/
	echo "--#3--=====MySQL=====-----"
	BACKUP_DIR=$target_path/mysql
	MYSQL_USER="backup"
	MYSQL=/usr/bin/mysql
	MYSQL_PASSWORD="backup666"
	MYSQLDUMP=/usr/bin/mysqldump
	
	mkdir -p $BACKUP_DIR
	
	databases=`$MYSQL --user=$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema)"`
	
	for db in $databases; do
	  $MYSQLDUMP --force --opt --skip-lock-tables --user=$MYSQL_USER -p$MYSQL_PASSWORD --databases $db | gzip > "$BACKUP_DIR/$db.gz"
	done
	echo "--#4--=====HomeDir Compress====---"
	homedirs=`ls /home/ | grep -v rtorrent`
        for homedir in $homedirs; do
		source_path=/home/$homedir/public_html
		if [ -d $source_path ] 
		then
                	sudo tar -pczf $target_path/www/$homedir.tar.gz /home/$homedir/public_html
		fi
        done
	echo "--#5--=====Compress Backup====---"
	tar -pczf $target_path.tar.gz $target_path
	echo "--#6--=====Cleanup=====---"
	rm -rf $target_path
fi
