#!/bin/bash

# ==============================================================================
# Oracle Export Backup Script
# ==============================================================================

# 날짜 설정
sysdate=$(date +%Y%m%d-%H%M)
log_date=$(date +%Y-%m-%d)

# ------------------------------------------------------------------------------
# 설정 (Configuration)
# ------------------------------------------------------------------------------

# 백업 기본 경로
base_backup_dir="/datadisk5/oracle_backup"

# 각 작업별 백업 디렉토리
# (Bash 3.x 호환성을 위해 연관 배열 대신 개별 변수 사용)
backup_dir_krtax="${base_backup_dir}/krtax"
backup_dir_ktp="${base_backup_dir}/ktp"
backup_dir_krtax_log="${base_backup_dir}/krtax_log"
backup_dir_ktp_tp="${base_backup_dir}/ktp_tp"

# par 파일 경로
par_dir="/datadisk1/oracle/oracle_backup/parfiles"

# 로그 파일 설정 (선택 사항: 로그 디렉토리가 없으면 기본 백업 디렉토리에 저장)
log_file="${base_backup_dir}/backup_${log_date}.log"

# 보존 기간 (일 단위)
retention_days="+1"

# ------------------------------------------------------------------------------
# 함수 정의 (Functions)
# ------------------------------------------------------------------------------

function log_msg {
    local msg="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $msg" | tee -a "$log_file"
}

cleanup_old_files() {
    local target_dir="$1"
    
    if [ -d "$target_dir" ]; then
        log_msg "Cleaning up old files in $target_dir (older than $retention_days days)..."
        # -ctime을 기존 스크립트와 동일하게 유지하되, 전체 삭제(rm *) 방지
        find "$target_dir" -type f -ctime "$retention_days" -exec rm -f {} \;
    else
        log_msg "Warning: Directory $target_dir does not exist."
    fi
}

cleanup_temp_par() {
    # 임시 생성된 par 파일 정리 (trap에 의해 호출됨)
    log_msg "Cleaning up temporary par files..."
    rm -f "${par_dir}"/*_"${sysdate}".par
}

perform_export() {
    local job_name="$1"      # e.g., krtax
    local par_template="$2"  # e.g., krtax.par
    
    local template_path="${par_dir}/${par_template}"
    local temp_par_path="${par_dir}/${job_name}_${sysdate}.par"

    log_msg "Starting export for $job_name..."

    if [ ! -f "$template_path" ]; then
        log_msg "Error: Template par file not found: $template_path"
        return 1
    fi

    # 1. 템플릿에서 sysdate 치환하여 임시 par 파일 생성
    sed "s/#DATE#/$sysdate/g" "$template_path" > "$temp_par_path"
    
    if [ $? -ne 0 ]; then
        log_msg "Error: Failed to create temporary par file for $job_name"
        return 1
    fi

    # 2. expdp 실행
    # expdp가 PATH에 있다고 가정 (필요시 절대경로 사용 또는 source profile)
    expdp PARFILE="$temp_par_path" >> "$log_file" 2>&1
    local exp_status=$?

    if [ $exp_status -eq 0 ]; then
        log_msg "Export for $job_name completed successfully."
    else
        # expdp는 경고와 함께 성공시 0이 아닌 값을 반환할 수도 있음 (예: 5=Warning)
        # 치명적 오류만 체크하려면 $? -gt 1 등을 사용할 수 있으나 여기선 단순 기록
        log_msg "Warning/Error: Export for $job_name finished with status $exp_status. Check logs."
    fi

    # 3. 개별 par 파일 즉시 삭제 (선택 사항, trap이 있어도 됨)
    rm -f "$temp_par_path"
}

# ------------------------------------------------------------------------------
# 메인 실행 (Main Execution)
# ------------------------------------------------------------------------------

# 스크립트 종료 시(정상/비정상) cleanup_temp_par 실행
trap cleanup_temp_par EXIT

log_msg "=== Backup Started ==="

# 1. 디렉토리 정리 (Retention Policy 적용)
cleanup_old_files "$backup_dir_krtax"
cleanup_old_files "$backup_dir_ktp"
cleanup_old_files "$backup_dir_krtax_log"
cleanup_old_files "$backup_dir_ktp_tp"

# 2. Export 수행
perform_export "krtax" "krtax.par"
perform_export "ktp" "ktp.par"
perform_export "krtax_log" "krtax_log.par"
perform_export "ktp_tp" "ktp_tp.par"

log_msg "=== Backup Finished ==="
