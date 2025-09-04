# pg_collect_pgsa

这是一个纯脚本工具，用于从PostgreSQL的pg_stat_activity视图中定期收集数据并保存到本地日志文件。

**相关背景**：

1. 某个慢SQL打满内存，导致系统kill掉postgres的某个进程，进而导致postgres进程重启，没有现场排查不了具体原因。（即使开启了慢SQL日志，没有执行完也不会记录到数据库日志中）
2. 数据库连接数被打满，PG相关监控数据丢失（因为也连不上数据库了），没有现场，不知道异常请求来源。

**特性**：

- 定期收集PostgreSQL活动会话信息
- 支持通过定时任务配置收集频率
- 提供日志文件自动分割功能
- 包含丰富的日志分析示例


## 安装指南

拉取代码，修改参数，设置定时任务。

```shell
# 克隆代码
git clone git@github.com:yansheng836/pg_collect_pgsa.git
cd pg_collect_pgsa

# 修改必要参数(均以 PG_ 开头，例如：PG_PATH、PG_HOST 等)
vi pg_collect_pgsa.sh

# 查路径
pwd

# crontab -e
# 每分钟执行
* * * * * pwd路径/pg_collect_pgsa.sh

# 每5秒执行（可自行调整秒数）
* * * * * pwd路径/pg_collect_pgsa_gap_second.sh 5
```

## 日志文件内容

测试版本：PostgreSQL 16.3 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 4.8.5 20150623 (Red Hat 4.8.5-44), 64-bit

输出字段为：now(),datid, datname, pid, leader_pid, usesysid, usename, application_name, client_addr, client_hostname, client_port, backend_start, xact_start, query_start, state_change, wait_event_type, wait_event, state, backend_xid, backend_xmin, query_id, query, backend_type

```plain
2025-08-28 13:02:22.151458+08|||29360||||||||2025-08-12 13:58:41.03657+08||||Activity|CheckpointerMain||||||checkpointer
2025-08-28 13:02:22.151458+08|||29361||||||||2025-08-12 13:58:41.036868+08||||Activity|BgWriterHibernate||||||background writer
2025-08-28 13:02:22.151458+08|||29363||||||||2025-08-12 13:58:41.043339+08||||Activity|WalWriterMain||||||walwriter
2025-08-28 13:02:22.151458+08|||29365||10|postgres|||||2025-08-12 13:58:41.04334+08||||Activity|LogicalLauncherMain||||||logical replication launcher
2025-08-28 13:02:22.151458+08|||29364||||||||2025-08-12 13:58:41.043811+08||||Activity|AutoVacuumMain||||||autovacuum launcher
2025-08-28 13:02:22.151458+08|5|postgres|6583||10|postgres|Navicat|42.99.63.72||36481|2025-08-28 12:34:20.191304+08||2025-08-28 12:47:55.618303+08|2025-08-28 12:47:55.619804+08|Client|ClientRead|idle|||7982016161531118154|SELECT now(),datid, datname, pid, leader_pid, usesysid, usename, application_name, client_addr, client_hostname, client_port, backend_start, xact_start, query_start, state_change, wait_event_type, wait_event, state, backend_xid, backend_xmin, query_id, query, backend_type from pg_stat_activity WHERE pid <> pg_backend_pid() ORDER BY backend_start ASC|client backend
2025-08-28 13:02:22.151458+08|5|postgres|6611||10|postgres|Navicat|42.99.63.72||36773|2025-08-28 12:34:26.810414+08||2025-08-28 12:47:55.670278+08|2025-08-28 12:47:55.670683+08|Client|ClientRead|idle|||7746404270258954630|SELECT c.conkey FROM pg_constraint c WHERE c.contype = 'p' and c.conrelid = 12222|client backend
2025-08-28 13:02:23.339309+08|||29360||||||||2025-08-12 13:58:41.03657+08||||Activity|CheckpointerMain||||||checkpointer
2025-08-28 13:02:23.339309+08|||29361||||||||2025-08-12 13:58:41.036868+08||||Activity|BgWriterHibernate||||||background writer
2025-08-28 13:02:23.339309+08|||29363||||||||2025-08-12 13:58:41.043339+08||||Activity|WalWriterMain||||||walwriter
2025-08-28 13:02:23.339309+08|||29365||10|postgres|||||2025-08-12 13:58:41.04334+08||||Activity|LogicalLauncherMain||||||logical replication launcher
2025-08-28 13:02:23.339309+08|||29364||||||||2025-08-12 13:58:41.043811+08||||Activity|AutoVacuumMain||||||autovacuum launcher
2025-08-28 13:02:23.339309+08|5|postgres|6583||10|postgres|Navicat|42.99.63.72||36481|2025-08-28 12:34:20.191304+08||2025-08-28 12:47:55.618303+08|2025-08-28 12:47:55.619804+08|Client|ClientRead|idle|||7982016161531118154|SELECT now(),datid, datname, pid, leader_pid, usesysid, usename, application_name, client_addr, client_hostname, client_port, backend_start, xact_start, query_start, state_change, wait_event_type, wait_event, state, backend_xid, backend_xmin, query_id, query, backend_type from pg_stat_activity WHERE pid <> pg_backend_pid() ORDER BY backend_start ASC|client backend
2025-08-28 13:02:23.339309+08|5|postgres|6611||10|postgres|Navicat|42.99.63.72||36773|2025-08-28 12:34:26.810414+08||2025-08-28 12:47:55.670278+08|2025-08-28 12:47:55.670683+08|Client|ClientRead|idle|||7746404270258954630|SELECT c.conkey FROM pg_constraint c WHERE c.contype = 'p' and c.conrelid = 12222|client backend

```


## 日志分析参考

### 1.简单检索

```shell
# cat/more/less/grep 
grep 'idle' pgsa.log

# 查找具体时间的相关日志
grep '2025-09-04 12:59' pgsa.log

# 在归档日志中，查找具体时间的相关日志
zless logs/pgsa-20250904-12.log.gz  | grep '2025-09-04 12:59'
```

### 2.统计不同状态的语句的数量

```shell
# 第18列是状态：state
awk -F '|' '{print $18}' pgsa.log | sort | uniq -c
     10 
      4 idle
```

### 3.按照时间统计

```shell
# 按天统计
awk -F '|' '{print $1}' pgsa.log | cut -d ' ' -f1 | sort | uniq -c
     14 2025-08-28
# 按小时统计
awk -F '[| ]' '{print $1 " " $2}' pgsa.log | cut -d: -f1 | sort | uniq -c
      7 2025-08-28 12
      7 2025-08-28 14
# 按分钟统计
awk -F '[| ]' '{print $1 " " $2}' pgsa.log | cut -d: -f1-2 | sort | uniq -c
      7 2025-08-28 12:59
      7 2025-08-28 14:09
```

## 注意事项

1. 在业务繁忙的数据库上使用时，需要注意日志文件可能会快速增长，建议在特殊情况下短暂使用，并密切关注磁盘空间。
2. `query`字段的长度受PostgreSQL参数`track_activity_query_size`限制，默认为1024，超出部分会被截断。修改此参数需要重启数据库服务。
3. 账号权限问题，可不使用postgres。推荐最小权限：[创建空库，]创建普通用户，授予`pg_read_all_stats`角色即可。
      ```sql
      -- CREATE DATABASE pgsadb;
      CREATE USER pgsa_user with password 'your password';
      GRANT pg_read_all_stats TO pgsa_user;
      ```

## 贡献

欢迎提交bug报告或功能需求：

GitHub：<https://github.com/yansheng836/pg_collect_pgsa/issues>

Gitee：<https://gitee.com/yansheng0083/pg_collect_pgsa/issues>

## License

使用 MIT License。有关详细信息，请参阅 [LICENSE.txt](./LICENSE.txt) 文件。
