#!/bin/bash
# Cấu hình PostgreSQL
CONTAINER_NAME="postgres"
DATABASE_NAME="postgres"
USER="postgres"
PASSWORD="postgres"
EXPORT_PATH="/home/hello/project/back_up_server/postgres"  # Thư mục lưu file backup
RETENTION_DAYS=3  # Số ngày giữ lại các file backup
RSYNC_PATH="/home/hello/project/back_up_server"
# Tạo thư mục nếu chưa tồn tại
mkdir -p "$EXPORT_PATH"

# Đặt tên file theo timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
EXPORT_FILE="$EXPORT_PATH/$DATABASE_NAME_$TIMESTAMP.sql"

# Export database từ container PostgreSQL
docker exec "$CONTAINER_NAME" pg_dump -U "$USER" "$DATABASE_NAME" > "$EXPORT_FILE"

# Kiểm tra nếu lệnh export thành công
# Kiểm tra nếu lệnh export thành công
if [ $? -eq 0 ]; then
    echo "Export thành công: $EXPORT_FILE"
    
    # Tiến hành đồng bộ hóa với S3
    echo "Đang đồng bộ hóa với S3..."
    rclone sync "$RSYNC_PATH" dem_xe_backup_data:/dem-xe-backup-data

    # Kiểm tra nếu lệnh rclone thành công
    if [ $? -eq 0 ]; then
        echo "Đồng bộ hóa thành công lên S3"
    else
        echo "Đồng bộ hóa thất bại"
        exit 1
    fi
else
    echo "Export thất bại, không thực hiện đồng bộ"
    exit 1
fi

find "$EXPORT_PATH" -type f -mtime +$RETENTION_DAYS -name "*.sql" -exec rm -f {} \;
