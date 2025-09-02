#!/bin/bash

# 设置脚本运行的最长时间（秒），这里设置为1分钟（60秒）
MAX_RUNTIME=60

# 记录脚本开始运行的时间（Unix时间戳）
START_TIME=$(date +%s)

while true; do
    # 在每次循环开始时检查是否超时
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED_TIME -ge $MAX_RUNTIME ]; then
        echo "脚本已运行超过 $MAX_RUNTIME 秒，即将退出..."
        exit 0
    fi

    sh /root/pg_collect_pgsa/pg_collect_pgsa.sh  # 替换为实际命令
    sleep 5
    #echo $1
    #sleep $0
    #exit 0
done

