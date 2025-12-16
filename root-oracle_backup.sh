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
# to Backup Storage (rsync로 변경하여 전송 효율성 및 안정성 확보)
rsync -av $backup_dir_krtax/krtax_$sysdate.* /bak_stg/db_backup/krtax/
rsync -av $backup_dir_ktp/ktp_$sysdate.* /bak_stg/db_backup/ktp/
rsync -av $backup_dir_krtax_log/krtax_log_$sysdate.* /bak_stg/db_backup/krtax_log/

# ------------------------------------------------------------------------------
# 백업 파일 정리 로직 (Retention Policy)
# 정책: 
# 1. 이번 달 및 지난 달 백업: 모두 보관
# 2. 지지난 달 이전 백업: 매월 첫 번째 백업 파일만 남기고 나머지 삭제
# ------------------------------------------------------------------------------

current_month=$(date +%Y%m)
last_month=$(date -d "1 month ago" +%Y%m)

# 정리 대상 디렉토리 목록
target_dirs=("/bak_stg/db_backup/krtax" "/bak_stg/db_backup/ktp" "/bak_stg/db_backup/krtax_log")

for target_dir in "${target_dirs[@]}"; do
    if [ -d "$target_dir" ]; then
        echo "Cleaning up directory: $target_dir"
        
        # 1. 해당 디렉토리의 파일들 중 '이번 달'과 '지난 달'을 제외한 오래된 파일들의 'YYYYMM' 추출
        # 파일명 형식 가정: *_YYYYMMDD-HHMM.* (예: krtax_20240101-1200.dmp)
        # awk로 구분자(_) 등을 이용해 날짜 부분을 파싱. 파일명 패턴에 따라 조정 필요.
        # 여기서는 파일명에 포함된 날짜(YYYYMM) 패턴을 찾아 추출.
        
        # 파일 목록에서 YYYYMM 형식 추출 (중복 제거)
        # ls 결과에서 날짜 패턴(8자리숫자-4자리숫자)을 찾아서 앞 6자리(YYYYMM)만 추출
        months_to_clean=$(find "$target_dir" -maxdepth 1 -type f -name "*_*-*.*" | \
            grep -oE '[0-9]{8}-[0-9]{4}' | \
            awk '{print substr($0, 1, 6)}' | \
            sort -u | \
            grep -v "$current_month" | \
            grep -v "$last_month")
            
        for month in $months_to_clean; do
            echo "  Processing old month: $month"
            
            # 해당 월의 파일들을 날짜순으로 정렬하여 조회
            # 파일명이 *_YYYYMM... 형식이므로 이름순 정렬이 곧 날짜순 정렬임
            files_in_month=$(ls $target_dir/*_${month}* 2>/dev/null | sort)
            
            count=0
            for file in $files_in_month; do
                if [ $count -eq 0 ]; then
                    echo "    [KEEP] $file (First backup of the month)"
                else
                    echo "    [DELETE] $file"
                    rm -f "$file"
                fi
                count=$((count + 1))
            done
        done
    else
        echo "Directory not found: $target_dir"
    fi
done