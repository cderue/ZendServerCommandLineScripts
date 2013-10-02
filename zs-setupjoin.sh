#!/bin/bash -ex

. ./globals.sh


export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
set -e

## Making sure wget and tar are present on the system

command -v wget >/dev/null 2>&1 || { echo >&2 "wget is not installed. Abort"; }
command -v tar >/dev/null 2>&1 || { echo >&2 "tar is not installed. Abort"; }

## Install Zend Server using Repoinstaller. 

cd /tmp
wget -q https://s3.amazonaws.com/nickscripts/ZendServer-6.1.0-RepositoryInstaller-linux.tar.gz
tar xvzf ZendServer-6.1.0-RepositoryInstaller-linux.tar.gz
ZendServer-RepositoryInstaller-linux/install_zs.sh "$zend_php_ver" --automatic

## Cleanup
cd /tmp
rm -rf *

## Bootstrap and Creat or Join cluster. Command line tool used "zs-manage"

/usr/local/zend/bin/zs-manage bootstrap-single-server -p "$zendadmin_ui_pass" -o "$zend_order_number" -l "$zend_license_key" -r TRUE -a TRUE -e "$zend_admin_email" -d "$zenddev_ui_pass" || true
web_api_key=`sqlite3 /usr/local/zend/var/db/gui.db "select HASH from GUI_WEBAPI_KEYS where NAME='admin';"`
/usr/local/zend/bin/zs-manage server-add-to-cluster -n "$zend_self_name" -i "$zend_self_addr" -o "$zend_db_host" -u "$zend_db_user" -p "$zend_db_password" -d "$zend_db_name" -K "$web_api_key" -N "admin"


## Restart Zend Server to check components status. 

/usr/local/zend/bin/zendctl.sh restart
