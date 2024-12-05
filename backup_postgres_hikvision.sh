#!/bin/bash

# Cấu hình thông tin PostgreSQL
CONTAINER_ID="a92413d0e6a1"  # ID của container PostgreSQL
POSTGRES_NAME="hki"
POSTGRES_SERVICE="hki"
EXPORT_PATH="/home/hello/project/back_up_server/postgres_hikvision"  # Thư mục lưu file backup
RETENTION_DAYS=3  # Số ngày giữ lại các file backup
RSYNC_PATH="/home/hello/project/back_up_server"

# Tạo thư mục lưu backup nếu chưa tồn tại
mkdir -p "$EXPORT_PATH"

# Đặt tên file backup theo timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
EXPORT_FILE="$EXPORT_PATH/$POSTGRES_SERVICE_$TIMESTAMP.sql"

# Export database từ container PostgreSQL sử dụng containerID
docker exec "$CONTAINER_ID" pg_dump -U "$POSTGRES_NAME" "$POSTGRES_SERVICE" > "$EXPORT_FILE"

# Kiểm tra nếu lệnh export thành công
if [ $? -eq 0 ]; then
    echo "Export thành công: $EXPORT_FILE"
else
    echo "Export thất bại, không thể tạo file backup."
    exit 1
fi

# Xóa các file backup cũ hơn số ngày giữ lại
find "$EXPORT_PATH" -type f -mtime +$RETENTION_DAYS -name "*.sql" -exec rm -f {} \;
