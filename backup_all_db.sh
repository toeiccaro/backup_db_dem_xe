#!/bin/bash

# Đảm bảo thư mục chứa log tồn tại
LOG_DIR="/home/hello/project/be_server"
mkdir -p "$LOG_DIR"

# Đường dẫn đến file log
LOG_FILE="$LOG_DIR/backup_db_log"

# Kiểm tra số dòng trong log, nếu lớn hơn 5000 thì reset lại
if [ -f "$LOG_FILE" ]; then
    LINE_COUNT=$(wc -l < "$LOG_FILE")
else
    LINE_COUNT=0
fi

if [ "$LINE_COUNT" -gt 5000 ]; then
    echo "Log file has more than 5000 lines. Resetting log." >> "$LOG_FILE"
    > "$LOG_FILE"  # Reset log file
fi

# Log time và bắt đầu backup
echo "$(date +"%Y-%m-%d %H:%M:%S") - Starting backup for all databases..." >> "$LOG_FILE"

# Chạy backup cho PostgreSQL - Dem Xe
echo "$(date +"%Y-%m-%d %H:%M:%S") - Starting backup for PostgreSQL (Dem Xe)..." >> "$LOG_FILE"
/home/hello/project/back_up_server/backup_postgres_dem_xe.sh >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") - PostgreSQL (Dem Xe) backup completed successfully." >> "$LOG_FILE"
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Error occurred during PostgreSQL (Dem Xe) backup." >> "$LOG_FILE"
fi

# Chạy backup cho PostgreSQL - Hikvision
echo "$(date +"%Y-%m-%d %H:%M:%S") - Starting backup for PostgreSQL (Hikvision)..." >> "$LOG_FILE"
/home/hello/project/back_up_server/backup_postgres_hikvision.sh >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") - PostgreSQL (Hikvision) backup completed successfully." >> "$LOG_FILE"
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Error occurred during PostgreSQL (Hikvision) backup." >> "$LOG_FILE"
fi

# Chạy backup cho SQL Server
echo "$(date +"%Y-%m-%d %H:%M:%S") - Starting backup for SQL Server..." >> "$LOG_FILE"
/home/hello/project/back_up_server/backup_sqlserver.sh >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") - SQL Server backup completed successfully." >> "$LOG_FILE"
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Error occurred during SQL Server backup." >> "$LOG_FILE"
fi

# Log kết thúc
echo "$(date +"%Y-%m-%d %H:%M:%S") - All backups completed." >> "$LOG_FILE"
