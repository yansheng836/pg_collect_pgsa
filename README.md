# pg_collect_pgsa

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/yansheng836/pg_collect_pgsa/shell-ci.yml?style=flat&label=build%3A%20shell-ci) ![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/yansheng836/pg_collect_pgsa/postgresql-ci-16.3.yml?style=flat&label=build%3A%20postgresql-ci-16.3) ![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/yansheng836/pg_collect_pgsa/postgresql-ci.yml?style=flat&label=build%3A%20postgresql-ci-10-17) 
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/yansheng836/pg_collect_pgsa) [![GitHub Issues](https://img.shields.io/github/issues/yansheng836/pg_collect_pgsa)](https://github.com/yansheng836/pg_collect_pgsa/issues) [![GitHub Pull Requests](https://img.shields.io/github/issues-pr/yansheng836/pg_collect_pgsa)](https://github.com/yansheng836/pg_collect_pgsa/pulls) [![GitHub Tag](https://img.shields.io/github/v/tag/yansheng836/pg_collect_pgsa)](https://github.com/yansheng836/pg_collect_pgsa/tags) [![GitHub Release](https://img.shields.io/github/v/release/yansheng836/pg_collect_pgsa)](https://github.com/yansheng836/pg_collect_pgsa/releases) ![GitHub Repo stars](https://img.shields.io/github/stars/yansheng836/pg_collect_pgsa) ![GitHub forks](https://img.shields.io/github/forks/yansheng836/pg_collect_pgsa) [![Codacy Badge](https://app.codacy.com/project/badge/Grade/4460db83948f4592ab825e8e900ec79f)](https://app.codacy.com/gh/yansheng836/pg_collect_pgsa/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade) [![GitHub License](https://img.shields.io/github/license/yansheng836/pg_collect_pgsa)](https://github.com/yansheng836/pg_collect_pgsa/blob/master/LICENSE.txt)

---

## 项目简介

**pg_collect_pgsa** (PostgreSQL Session Activity Collector) 是一个纯 Shell 脚本工具，用于定期从 PostgreSQL 的 `pg_stat_activity` 视图中收集会话活动数据并保存到本地日志文件。

**支持版本**：PostgreSQL 10, 11, 12, 13, 14, 15, 16, 17, 18。

**设计理念**：轻量级、零依赖、高可用、易部署。

## 使用场景

这个工具主要解决以下 PostgreSQL 运维痛点：

| 场景 | 问题 | 解决方案 |
|------|------|----------|
| **慢 SQL 导致崩溃** | 某个慢 SQL 打满内存，导致系统 OOM kill 掉 PostgreSQL 进程，即使开启了慢 SQL 日志，未执行完的 SQL 也不会被记录。 | 工具持续记录会话活动，崩溃前的现场已保存。 |
| **连接数耗尽** | 数据库连接数被打满时，监控工具连不上数据库，无法获取异常请求来源。 | 本地日志已记录连接耗尽前的所有会话信息。 |
| **事后分析** | 需要了解某一时刻的数据库活动情况，但没有历史记录。 | 按时间归档的日志可随时回溯分析。 |

## 功能特性

- ✅ **自动版本适配** - 自动检测 PostgreSQL 版本并生成兼容的 SQL
- ✅ **进程单例保护** - 使用 `flock` 防止脚本并发执行
- ✅ **智能日志轮转** - 支持按小时和按大小（默认 1GB）双重轮转
- ✅ **日志压缩存储** - 自动 gzip 压缩归档日志（压缩率约 99%）
- ✅ **灵活的采集频率** - 支持分钟级（cron）和秒级（gap 脚本）采集
- ✅ **丰富的错误处理** - 密码错误、连接数满等场景都有明确提示
- ✅ **环境变量支持** - 支持通过环境变量覆盖配置，方便容器化部署
- ✅ **详细的调试日志** - `debug.log` 记录脚本执行过程，便于排查问题

## 快速开始

### 1. 安装

```bash
# 克隆仓库
git clone https://github.com/yansheng836/pg_collect_pgsa.git
cd pg_collect_pgsa

# 或者使用 Gitee
git clone https://gitee.com/yansheng0083/pg_collect_pgsa.git
```

### 2. 配置数据库连接

编辑 `pg_collect_pgsa.sh`，修改开头的配置参数：

```bash
vi pg_collect_pgsa.sh
```

主要配置项（文件第 6-13 行）：
```bash
PG_PATH="/usr/local/pgsql/bin/"        # psql 所在路径
PG_HOST="localhost"                     # 数据库主机
PG_PORT="5432"                          # 数据库端口
PG_USER="postgres"                      # 数据库用户
PG_PASSWORD="your_password"             # 数据库密码
PG_DATABASE="postgres"                   # 连接的数据库名
```

> **安全提示**：也可以使用 `.pgpass` 文件或配置 `pg_hba.conf` 免密登录，避免在脚本中明文写密码。

### 3. 创建最小权限用户（推荐）

不需要使用 `postgres` 超级用户，建议创建专用监控用户：

```sql
-- 连接到 PostgreSQL
psql -U postgres

-- 创建监控用户
CREATE USER pgsa_user WITH PASSWORD 'your_secure_password';

-- 授予读取统计信息的权限（PG 10+）
GRANT pg_read_all_stats TO pgsa_user;
```

### 4. 测试运行

```bash
# 手动执行一次测试
./pg_collect_pgsa.sh

# 检查是否生成日志
ls -lh pgsa.log debug.log
```

### 5. 设置定时任务

使用 `crontab -e` 编辑定时任务：

```bash
# 方案 A：每分钟采集一次（推荐用于常规监控）
* * * * * /full/path/to/pg_collect_pgsa.sh

# 方案 B：每 5 秒采集一次（用于需要高频监控的场景）
* * * * * /full/path/to/pg_collect_pgsa_gap_second.sh 5
```

> 注意：请使用绝对路径！可以通过 `pwd` 命令查看当前路径。

---

## 配置说明

### 环境变量配置

脚本支持通过环境变量覆盖默认配置，这在容器化部署时特别有用：

| 环境变量 | 默认值 | 说明 |
|---------|--------|------|
| `PG_PATH` | `/usr/local/pgsql/bin/` | PostgreSQL 二进制文件路径 |
| `PG_HOST` | `localhost` | 数据库主机地址 |
| `PG_PORT` | `54321` | 数据库端口 |
| `PG_USER` | `postgres` | 数据库用户名 |
| `PG_PASSWORD` | `your_password` | 数据库密码 |
| `PG_DATABASE` | `postgres` | 连接的数据库名 |

示例：
```bash
# 使用环境变量运行
PG_PORT=5432 PG_PASSWORD=mypass ./pg_collect_pgsa.sh
```

### 日志配置

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `LOG_FILE` | `./pgsa.log` | 当前活动日志文件 |
| `MAX_LOG_SIZE` | `1GB` | 单日志文件最大大小 |
| 归档目录 | `./logs/` | 压缩日志存放目录 |

修改日志大小限制（第 26 行）：
```bash
MAX_LOG_SIZE=$((1024 * 1024 * 1024))  # 1GB
# MAX_LOG_SIZE=$((2 * 1024 * 1024 * 1024))  # 改为 2GB
```

---

## 日志格式

### 输出字段说明

日志使用 `|` 作为分隔符，包含以下字段：

| 序号 | 字段名 | 说明 |
|-----|--------|------|
| 1 | `now()` | 采集时间戳 |
| 2 | `datid` | 数据库 OID |
| 3 | `datname` | 数据库名称 |
| 4 | `pid` | 后端进程 ID |
| 5 | `leader_pid` | 并行组的领导者 PID (PG13+) |
| 6 | `usesysid` | 用户 OID |
| 7 | `usename` | 用户名 |
| 8 | `application_name` | 应用名称 |
| 9 | `client_addr` | 客户端地址 |
| 10 | `client_hostname` | 客户端主机名 |
| 11 | `client_port` | 客户端端口 |
| 12 | `backend_start` | 后端进程启动时间 |
| 13 | `xact_start` | 当前事务开始时间 |
| 14 | `query_start` | 当前查询开始时间 |
| 15 | `state_change` | 上次状态变更时间 |
| 16 | `wait_event_type` | 等待事件类型 |
| 17 | `wait_event` | 等待事件名称 |
| 18 | `state` | 会话状态 |
| 19 | `backend_xid` | 后端事务 ID |
| 20 | `backend_xmin` | 后端 xmin 地平线 |
| 21 | `query_id` | 查询 ID (PG14+) |
| 22 | `query` | 执行的 SQL 语句 |
| 23 | `backend_type` | 后端类型 |

### 版本兼容性

| PostgreSQL 版本 | 兼容处理 |
|----------------|---------|
| 14-18 | 使用全部原生字段 |
| 13 | `query_id` 字段为 NULL |
| 10-12 | `leader_pid` 和 `query_id` 字段为 NULL |

### 日志示例

```plain
2025-08-28 13:02:22.151458+08|5|postgres|6583||10|postgres|Navicat|42.99.63.72||36481|2025-08-28 12:34:20.191304+08||2025-08-28 12:47:55.618303+08|2025-08-28 12:47:55.619804+08|Client|ClientRead|idle|||7982016161531118154|SELECT ...|client backend
```

---

## 日志分析示例

### 基础检索

```bash
# 查看当前日志
tail -f pgsa.log

# 查找包含 "idle" 状态的记录
grep '|idle|' pgsa.log

# 查找特定时间点的记录
grep '2025-09-04 12:59' pgsa.log

# 在归档日志中搜索（已压缩）
zcat logs/pgsa-20250904-12.log.gz | grep '2025-09-04 12:59'
zgrep '2025-09-04 12:59' logs/pgsa-20250904-12.log.gz
```

### 统计分析

```bash
# 统计各状态的会话数量（第 18 列是 state）
awk -F '|' '{print $18}' pgsa.log | sort | uniq -c | sort -rn

# 示例输出：
#    156 idle
#     23 active
#      5 idle in transaction

# 按用户统计（第 7 列是 usename）
awk -F '|' '{print $7}' pgsa.log | sort | uniq -c | sort -rn

# 按客户端 IP 统计（第 9 列是 client_addr）
awk -F '|' '{print $9}' pgsa.log | sort | uniq -c | sort -rn
```

### 时间维度分析

```bash
# 按天统计采集次数
awk -F '|' '{print substr($1, 1, 10)}' pgsa.log | sort | uniq -c

# 按小时统计
awk -F '|' '{print substr($1, 1, 13)}' pgsa.log | sort | uniq -c

# 按分钟统计
awk -F '|' '{print substr($1, 1, 16)}' pgsa.log | sort | uniq -c
```

### 高级分析

```bash
# 查找运行时间超过 5 分钟的活跃会话
awk -F '|' '$18 == "active" {print $0}' pgsa.log

# 提取所有 SQL 语句（第 22 列）
awk -F '|' '{print $22}' pgsa.log | head -50

# 查找包含特定表名的查询
grep '|SELECT.*users|' pgsa.log

# 查看哪个 IP 连接最多
awk -F '|' '$9 != "" {print $9}' pgsa.log | sort | uniq -c | sort -rn | head -10
```

---

## 注意事项

### 磁盘空间

- **日志增长速度**：在繁忙的数据库上，日志文件可能会快速增长
- **建议**：
  - 密切关注磁盘空间使用情况
  - 根据实际情况调整 `MAX_LOG_SIZE` 参数
  - 定期清理旧的归档日志
- **压缩率**：测试显示 2.8GB 纯文本可压缩至约 19MB（~99% 压缩率）

### SQL 截断

`query` 字段的长度受 PostgreSQL 参数 `track_activity_query_size` 限制：
- 默认值：1024 字节
- 超出部分会被截断
- 修改此参数需要重启数据库服务

```sql
-- 查看当前值
SHOW track_activity_query_size;

-- 修改（需要重启生效）
ALTER SYSTEM SET track_activity_query_size = 4096;
```

### 权限建议

| 用户类型 | 权限 | 说明 |
|---------|------|------|
| 最小权限 | `pg_read_all_stats` | 推荐用于生产环境 |
| 超级用户 | `postgres` | 不推荐，权限过大 |

### 生产环境部署检查清单

- [ ] 使用专用监控用户而非 `postgres`
- [ ] 配置 `.pgpass` 或 `pg_hba.conf` 免密登录
- [ ] 监控脚本运行状态（检查 `debug.log`）
- [ ] 配置日志目录的磁盘空间告警
- [ ] 建立旧日志归档/清理策略
- [ ] 验证日志轮转是否正常工作

---

## 故障排查

### 脚本执行失败

检查调试日志：
```bash
tail -f debug.log
```

### 常见错误

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `password authentication failed` | 密码错误 | 检查 `PG_PASSWORD` 或 `.pgpass` |
| `too many clients already` | 连接数已满 | 日志中已记录当时状态，可事后分析 |
| `could not connect to server` | 连接失败 | 检查 `PG_HOST`、`PG_PORT` 和网络 |
| `获取锁失败，进程已在运行中` | 脚本并发 | 前一次执行还未完成，无需处理 |

### 验证采集是否正常

```bash
# 1. 检查进程是否在运行（如果使用 gap 脚本）
ps aux | grep pg_collect

# 2. 检查日志是否在更新
ls -lh pgsa.log

# 3. 查看调试日志
tail debug.log
```

---

## 贡献指南

欢迎提交 Issue 和 Pull Request！

- **GitHub**: [https://github.com/yansheng836/pg_collect_pgsa/issues](https://github.com/yansheng836/pg_collect_pgsa/issues)
- **Gitee**: [https://gitee.com/yansheng0083/pg_collect_pgsa/issues](https://gitee.com/yansheng0083/pg_collect_pgsa/issues)

### 开发流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE.txt](./LICENSE.txt) 文件。

---

**如果这个工具对你有帮助，请给个 Star ⭐ 支持一下！**
