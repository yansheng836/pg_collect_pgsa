# pg_collect_pgsa

纯脚本收集pg_stat_activity的数据到本地。

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
# cat/more/less/grep/ 
grep 'idle' pgsa.log
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
# 按天
awk -F '|' '{print $1}' pgsa.log | cut -d ' ' -f1 | sort | uniq -c
     14 2025-08-28
# 按小时
awk -F '[| ]' '{print $1 " " $2}' pgsa.log | cut -d: -f1 | sort | uniq -c
      7 2025-08-28 12
      7 2025-08-28 14
# 按分钟
awk -F '[| ]' '{print $1 " " $2}' pgsa.log | cut -d: -f1-2 | sort | uniq -c
      7 2025-08-28 12:59
      7 2025-08-28 14:09
```
