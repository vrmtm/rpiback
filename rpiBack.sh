#!/bin/bash


SUBDIR=rpiBack
DIR=/mnt/nuc/$SUBDIR

echo "Starting RaspberryPI backup process!"

PACKAGESTATUS=`dpkg -s pv | grep Status`;

if [[ $PACKAGESTATUS == S* ]]
   then
      echo "Package 'pv' is installed."
   else
      echo "Package 'pv' is NOT installed."
      echo "Installing package 'pv'. Please wait..."
      apt-get -y install pv
fi

if [ ! -d "$DIR" ];
   then
      echo "Backup directory $DIR doesn't exist, creating it now!"
      mkdir $DIR
fi

OFILE="$DIR/backup_$(date +%Y%m%d_%H%M%S)"

OFILEFINAL=$OFILE.img

sync; sync

echo "Stopping some services before backup."
service apache2 stop
service mysql stop
service cron stop

echo "Backing up SD card to USB HDD."
echo "This will take some time depending on your SD card size and read performance. Please wait..."
SDSIZE=`blockdev --getsize64 /dev/mmcblk0`;
pv -tpreb /dev/mmcblk0 -s $SDSIZE | dd of=$OFILE bs=1M conv=sync,noerror iflag=fullblock

RESULT=$?

echo "Start the stopped services again."
service apache2 start
service mysql start
service cron start

if [ $RESULT = 0 ];
   then
      echo "Successful backup, previous backup files will be deleted."
      rm -f $DIR/backup_*.tar.gz
      mv $OFILE $OFILEFINAL
      echo "Backup is being tarred. Please wait..."
      echo "RaspberryPI backup process completed! FILE: $OFILEFINAL"
      exit 0
   else
      echo "Backup failed! Previous backup files untouched."
      echo "Please check there is sufficient space on the HDD."
      rm -f $OFILE
      echo "RaspberryPI backup process failed!"
      exit 1
fi
