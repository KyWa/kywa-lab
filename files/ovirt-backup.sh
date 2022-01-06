#!/bin/bash

# mount backup share
mount -t nfs 10.0.0.10:/volume1/backups/ovirt /ovirtbackup

backup_file="`date "+%Y-%m-%d"`-backup"

engine-backup --mode=backup --file=/ovirtbackup/$backup_file --log=/ovirtbackup/$backup_file.log

# unmount backup share
umount /ovirtbackup
