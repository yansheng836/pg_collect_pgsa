#!/bin/bash

# 设置脚本运行的最长时间（秒），这里设置为1分钟（60秒）
MAX_RUNTIME=60

# 设置默认睡眠时间为5秒
DEFAULT_SLEEP=5

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

# 检查是否有参数传入
if [ $# -eq 0 ]; then
    DEFAULT_SLEEP=5
    #echo "未提供参数，使用默认睡眠时间: ${DEFAULT_SLEEP}秒"
else
    # 有参数
    # 校验参数是否为 (0-60) 的整数
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "入参错误：参数 '$1' 不是整数。"
        exit 1
    fi

    if [ "$1" -le 0 ] || [ "$1" -ge 60 ]; then
        echo "入参错误：参数 '$1' 超出范围，请输入 (0-60) 之间的整数，不包括0和60。"
        exit 1
    else
        DEFAULT_SLEEP=$1
    fi
fi

# 记录脚本开始运行的时间（Unix时间戳）
START_TIME=$(date +%s)
while true; do
    # 在每次循环开始时检查是否超时
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED_TIME -ge $MAX_RUNTIME ]; then
        #echo "脚本已运行超过 $MAX_RUNTIME 秒，退出。"
        exit 0
    fi

    #执行主要命令
    sh "$script_dir/pg_collect_pgsa.sh"

    #sleep 5
    sleep "$DEFAULT_SLEEP"
done

