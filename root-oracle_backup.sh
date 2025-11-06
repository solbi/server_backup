#!/bin/bash

sysdate=$(date +%Y%m%d-%H%M)

# 백업 대상 경로
backup_dir_base=/datadisk5/oracle_backup
backup_dir_krtax=$backup_dir_base/krtax
backup_dir_ktp=$backup_dir_base/ktp
backup_dir_krtax_log=$backup_dir_base/krtax_log

# Oracle 백업
su - oracle -c /datadisk1/oracle/oracle_backup/oracle_backup.sh

# to Backup Storage
cp $backup_dir_krtax/krtax_$sysdate.* /bak_stg/db_backup/krtax
cp $backup_dir_ktp/ktp_$sysdate.* /bak_stg/db_backup/ktp
cp $backup_dir_krtax_log/krtax_log_$sysdate.* /bak_stg/db_backup/krtax_log

# 백업파일 정리
#find /bak_stg/db_backup/krtax/ -ctime +10 -exec rm -f {} \;
#find /bak_stg/db_backup/ktp/ -ctime +30 -exec rm -f {} \;
#find /bak_stg/db_backup/krtax_log/ -ctime +30 -exec rm -f {} \;