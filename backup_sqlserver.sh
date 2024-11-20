#!/bin/bash
# Cấu hình SQL Server
CONTAINER_NAME="sqlserver_be"
DATABASE_NAME="Scale"  # Tên cơ sở dữ liệu cần sao lưu
USER="sa"
PASSWORD="19921999aA*"  # Mật khẩu SA
EXPORT_PATH="/home/hello/project/back_up_server/sqlserver"  # Thư mục lưu file backup
RETENTION_DAYS=3  # Số ngày giữ lại các file backup
RSYNC_PATH="/home/hello/project/back_up_server"
CONTAINER_BACKUP_PATH="/var/opt/mssql/data"  # Thư mục trong container mà SQL Server có quyền ghi

# Tạo thư mục nếu chưa tồn tại
mkdir -p "$EXPORT_PATH"

# Đặt tên file theo timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
EXPORT_FILE="$EXPORT_PATH/$DATABASE_NAME_$TIMESTAMP.bak"

# Export database từ container SQL Server
docker exec "$CONTAINER_NAME" /opt/mssql-tools/bin/sqlcmd -S localhost -U "$USER" -P "$PASSWORD" -Q "BACKUP DATABASE [$DATABASE_NAME] TO DISK = N'$CONTAINER_BACKUP_PATH/$DATABASE_NAME_$TIMESTAMP.bak'"

# Kiểm tra nếu lệnh backup thành công
if [ $? -eq 0 ]; then
    echo "Backup thành công: $EXPORT_FILE"

    # Sao chép file sao lưu từ container ra ngoài host
    docker cp "$CONTAINER_NAME:$CONTAINER_BACKUP_PATH/$DATABASE_NAME_$TIMESTAMP.bak" "$EXPORT_FILE"

    # Kiểm tra nếu sao chép file thành công
    if [ $? -eq 0 ]; then
        echo "File sao lưu đã được sao chép thành công từ container ra ngoài: $EXPORT_FILE"

        # Thay đổi quyền sở hữu file sao lưu
        sudo chown hello:hello "$EXPORT_FILE"

        # Đồng bộ hóa lên S3
        echo "Đang đồng bộ hóa với S3..."
        rclone sync "$RSYNC_PATH" dem_xe_backup_data:/dem-xe-backup-data
        
        if [ $? -eq 0 ]; then
            echo "Đồng bộ hóa lên S3 thành công."
        else
            echo "Đồng bộ hóa lên S3 thất bại."
            exit 1
        fi
    else
        echo "Sao chép file sao lưu thất bại."
        exit 1
    fi
else
    echo "Backup thất bại"
    exit 1
fi

# Xóa các file sao lưu cũ hơn số ngày giữ lại
find "$EXPORT_PATH" -type f -mtime +$RETENTION_DAYS -name "*.bak" -exec rm -f {} \;
