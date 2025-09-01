#!/bin/bash
#PostgreSQL连接参数
PG_HOST="localhost"
PG_PORT="54321"
PG_USER="postgres"
PG_PASSWORD="your_password"  # 替换为实际密码
PG_DATABASE="postgres"
# LOG_FILE="/tmp/pgsa.log"
LOG_FILE="./pgsa.log"
PWD_DIR=`pwd`
#echo $PWD_DIR
cd $PWD_DIR

#MAX_LOG_SIZE=$((1024 * 1024 * 1024)) # 1GB
MAX_LOG_SIZE=$((1)) # 1GB

# 获取当前时间戳（用于日志分割）
CURRENT_TIME=$(date +"%Y%m%d-%H%M%S")  # 精确到秒
CURRENT_HOUR=$(date +"%Y%m%d-%H")      # 精确到小时

# 确保日志目录存在
init_directories() {
    mkdir -p "$PWD_DIR/logs"
}

# 检查并分割日志文件
check_and_split_log() {
    if [ -f "$LOG_FILE" ]; then
        # 检查文件大小
        file_size=$(stat -c%s "$LOG_FILE")
        if [ "$file_size" -ge "$MAX_LOG_SIZE" ]; then
            # 获取文件创建时间（精确到秒）
            file_time=$(date -r "$LOG_FILE" +"%Y%m%d-%H%M%S")
            # 分割并压缩日志文件
            gzip -c "$LOG_FILE" > "./logs/pas-${file_time}.log.gz"
            # 清空原日志文件
            > "$LOG_FILE"
            echo "日志已分割并压缩为 ./logs/pas-${file_time}.log.gz"
        fi
    fi
    
    # 每小时创建新日志文件
    if [ ! -f "$LOG_FILE" ] || [ "$(date -r "$LOG_FILE" +"%Y%m%d-%H")" != "$CURRENT_HOUR" ]; then
        if [ -f "$LOG_FILE" ]; then
            file_time=$(date -r "$LOG_FILE" +"%Y%m%d-%H%M%S")
            gzip -c "$LOG_FILE" > "./logs/pas-${file_time}.log.gz"
        fi
        > "$LOG_FILE"  # 创建新的空日志文件
    fi
}

# 执行PostgreSQL查询并记录到日志文件
execute_pg_query() {
    #echo 'begin.' >> "$LOG_FILE"
    {
        #echo "=== 记录时间: $(date '+%Y-%m-%d %H:%M:%S') ==="
        # 查询pg_stat_activity视图
        PGPASSWORD="$PG_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" \
            -A -t -c "SELECT now(),datid, datname, pid, leader_pid, usesysid, usename, application_name, client_addr, client_hostname, client_port, backend_start, xact_start, query_start, state_change, wait_event_type, wait_event, state, backend_xid, backend_xmin, query_id, query, backend_type from pg_stat_activity WHERE pid <> pg_backend_pid() ORDER BY backend_start ASC;"
        #echo ""
    } >> "$LOG_FILE"
    #echo 'end.' >> "$LOG_FILE"
}

# 主函数
main() {
    init_directories
    check_and_split_log
    execute_pg_query
}

main

