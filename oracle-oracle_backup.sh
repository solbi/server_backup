#!/bin/bash

sysdate=$(date +%Y%m%d-%H%M)

# 백업 대상 경로
backup_dir_base=/datadisk5/oracle_backup
backup_dir_krtax=$backup_dir_base/krtax
backup_dir_ktp=$backup_dir_base/ktp
backup_dir_krtax_log=$backup_dir_base/krtax_log
backup_dir_ktp_tp=$backup_dir_base/ktp_tp

# par 파일 경로
par_dir=/datadisk1/oracle/oracle_backup/parfiles

# 백업 파일 정리
rm -f $backup_dir_krtax/*
find $backup_dir_ktp/ -ctime +1 -exec rm -f {} \;
find $backup_dir_krtax_log/ -ctime +1 -exec rm -f {} \;
find $backup_dir_ktp_tp/ -ctime +1 -exec rm -f {} \;

# krtax export
sed "s/#DATE#/$sysdate/g" $par_dir/krtax.par > $par_dir/krtax_$sysdate.par
expdp PARFILE=$par_dir/krtax_$sysdate.par > /dev/null 2>&1
rm -f $par_dir/krtax_$sysdate.par

# ktp export
sed "s/#DATE#/$sysdate/g" $par_dir/ktp.par > $par_dir/ktp_$sysdate.par
expdp PARFILE=$par_dir/ktp_$sysdate.par > /dev/null 2>&1
rm -f $par_dir/ktp_$sysdate.par

# krtax_log export (krtax_log 및 중요 테이블 백업)
sed "s/#DATE#/$sysdate/g" $par_dir/krtax_log.par > $par_dir/krtax_log_$sysdate.par
expdp PARFILE=$par_dir/krtax_log_$sysdate.par > /dev/null 2>&1
rm -f $par_dir/krtax_log_$sysdate.par

# ktp_tp export
sed "s/#DATE#/$sysdate/g" $par_dir/ktp_tp.par > $par_dir/ktp_tp_$sysdate.par
expdp PARFILE=$par_dir/ktp_tp_$sysdate.par > /dev/null 2>&1
rm -f $par_dir/ktp_tp_$sysdate.par