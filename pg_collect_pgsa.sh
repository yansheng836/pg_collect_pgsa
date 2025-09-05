#!/bin/bash

#<<<<<<<< 需要修改的参数 <<<<<<<<<
# 设置 PATH，添加 psql 所在路径（ whereis psql ）
# 兼容ci，如果有环境变量，优先使用环境变量，否则使用默认值
PG_PATH="${PG_PATH:-/usr/local/pgsql/bin/}"
export PATH=$PG_PATH:$PATH
#PostgreSQL连接参数
PG_HOST="${PG_HOST:-localhost}"
PG_PORT="${PG_PORT:-54321}"
PG_USER="${PG_USER:-postgres}"
PG_PASSWORD="${PG_PASSWORD:-your_password}" # 替换为实际密码，或者使用.pgpass文件进行校验，或者pg_hba.conf有针对性的配置免密
PG_DATABASE="${PG_DATABASE:-postgres}"
#>>>>>>>>>> 需要修改的参数 >>>>>>>>

#echo "当前文件名:"$0 # 如果是绝对路径，会直接打印；而不是文件名
script_path=$(readlink -f "$0")
# 获取当前脚本的名称（不包含路径）
script_name=$(basename "$0")
#echo $script_name
# 获取当前脚本的目录
script_dir=$(dirname "$script_path")

LOG_FILE="$script_dir/pgsa.log"

MAX_LOG_SIZE=$((1024 * 1024 * 1024)) # 1GB，纯文本的压缩率较高（测试 2.8GB-->19MB，压缩率约 99%），如果觉得小了，可以自行调整

# 获取当前时间戳（用于日志分割）
CURRENT_HOUR=$(date +"%Y%m%d-%H")      # 精确到小时

batchid=$(date +"%Y%m%d_%H%M%S_%N")

# 日志记录函数
# 函数名: log_message
# 描述: 将日志消息输出到指定日志文件
# 参数: 
#   $1 - 日志级别 (INFO, WARNING, ERROR)
#   $2 - 日志消息内容
log_message() {
    # 确保日志目录存在
    # 定义日志文件路径
    SHELL_LOG_FILE="$script_dir/debug.log"

    local log_level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N')|$batchid|[$log_level]|$message" | tee -a "$SHELL_LOG_FILE"
}

# 检查当前脚本进程是否已存在的函数
check_existing_process() {
    LOCK_FILE="$script_dir/${0##*/}.lock" # 根据脚本名称生成锁文件
    exec 9>"$LOCK_FILE" # 将文件描述符9与锁文件关联

    if flock -n 9; then # 非阻塞模式尝试获取排他锁
        # 设置 trap：无论在什么情况下退出，都释放锁并删除锁文件
        trap 'flock -u 9; rm -f "$LOCK_FILE"; exit' INT TERM EXIT
        #log_message "INFO" "获取锁成功，进程 $script_name 不存在，开始执行脚本。"
    else
        log_message "WARNING" "获取锁失败，进程 $script_name 已在运行中，退出脚本。"
        exit 1
    fi
}


# 检查并分割日志文件
check_and_split_log() {
    # 确保日志目录存在
    mkdir -p "$script_dir/logs"

    # 按照日志文件时间（每小时）分割文件
    if [ ! -f "$LOG_FILE" ] || [ "$(date -r "$LOG_FILE" +"%Y%m%d-%H")" != "$CURRENT_HOUR" ]; then
        if [ -f "$LOG_FILE" ]; then
            file_time=$(date -r "$LOG_FILE" +"%Y%m%d-%H")
            gzip_file_name="$script_dir/logs/pgsa-${file_time}.log.gz"
            # 分割并压缩日志文件
            gzip -c "$LOG_FILE" > "$gzip_file_name"
            log_message "INFO" "按小时分割日志，日志已分割并压缩为 $gzip_file_name 。"

            # 清空原日志文件
            > "$LOG_FILE"
        fi
    fi

    # 按照日志文件大小分割文件
    if [ -f "$LOG_FILE" ]; then
        # 检查文件大小
        file_size=$(stat -c%s "$LOG_FILE")
        if [ "$file_size" -ge "$MAX_LOG_SIZE" ]; then
            # 获取文件创建时间（精确到秒）
            file_time=$(date -r "$LOG_FILE" +"%Y%m%d-%H%M%S")
            gzip_file_name="$script_dir/logs/pgsa-${file_time}.log.gz"
            # 分割并压缩日志文件
            gzip -c "$LOG_FILE" > "$gzip_file_name"
            log_message "INFO" "日志大小达到阈值[$MAX_LOG_SIZE]，日志已分割并压缩为 $gzip_file_name 。"

            # 清空原日志文件
            > "$LOG_FILE"
        fi
    fi
}

# 执行PostgreSQL查询并记录到日志文件
execute_pg_query() {
    log_message "INFO" "开始查询数据库..."
    
    # 查询pg_stat_activity视图
    ERROR_OUTPUT=$(PGPASSWORD="$PG_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" \
        -A -t -c "SELECT now(),datid, datname, pid, leader_pid, usesysid, usename, application_name, client_addr, client_hostname, client_port, backend_start, xact_start, query_start, state_change, wait_event_type, wait_event, state, backend_xid, backend_xmin, query_id, query, backend_type from pg_stat_activity WHERE pid <> pg_backend_pid() ORDER BY backend_start ASC;" 2>&1 >> "$LOG_FILE")

    EXIT_STATUS=$?
    #echo "ERROR_OUTPUT:"$ERROR_OUTPUT
    #echo "EXIT_STATUS:"$EXIT_STATUS

    # 检查执行状态
    if [ $EXIT_STATUS -eq 0 ]; then
        #echo "SQL命令执行成功。"
        log_message "INFO" "SQL命令执行成功。"
    else
        #echo "SQL命令执行失败，错误信息：$ERROR_OUTPUT"
        log_message "ERROR" "SQL命令执行失败，错误信息为：$ERROR_OUTPUT"
        # 根据错误信息进行更精细化的判断和处理
        if echo "$ERROR_OUTPUT" | grep -q "password authentication failed"; then
            #echo "错误：密码认证失败，请检查用户名和密码。"
            log_message "ERROR" "错误：密码认证失败，请检查用户名和密码。"
            exit 1
        elif echo "$ERROR_OUTPUT" | grep -q "too many clients already"; then
            #echo "错误：数据库连接数已满。"
            log_message "ERROR" "错误：数据库连接数已满。"
            # 可以在这里加入处理连接数满的代码，例如重试或终止空闲连接
            exit 1
        # ... 其他错误类型的判断和处理
        else
            #echo "未知错误。"
            log_message "ERROR" "错误：未知错误，详见报错信息。"
            exit 1
        fi
    fi

    log_message "INFO" "查询数据库结束。"
}

# 主函数
main() {
    log_message "INFO" "begin..."
    check_existing_process
    check_and_split_log
    execute_pg_query
    log_message "INFO" "end!"
}

main
