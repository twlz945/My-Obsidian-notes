MySQL 是全球使用最广泛的开源关系型数据库，以其高性能、高可靠性和易用性著称，是 Web 应用后端存储的事实标准。

### MySQL 是什么？

MySQL 是一个基于客户端-服务器模型的关系型数据库管理系统（RDBMS），使用 SQL（结构化查询语言）进行数据操作。它采用**插件式存储引擎架构**，核心引擎是 **InnoDB**，支持事务（ACID）、行级锁、外键等关键特性。

---

### 2026 年版本现状（关键！）

截至 2026 年，MySQL 采用 **LTS（长期支持）+ 创新版**双轨发布模型：

| 版本 | 状态 | 说明 |
|------|------|------|
| **MySQL 5.7** | 已 EOL | 仍有大量存量系统在使用，但无安全补丁 |
| **MySQL 8.0** | **2026年4月正式 EOL** | 不再提供官方安全补丁，约58%存量实例仍在此版本 |
| **MySQL 8.4 LTS** | **当前生产推荐版本** | 首个 LTS 版本，支持至 2032 年，聚焦稳定性 |
| **MySQL 9.7 LTS** | 新一代 LTS（2026年4月发布） | 支持至 2034 年，引入 AI/向量等新特性 |
| **MySQL 26.x** | 创新版（季度发布） | 采用 `yy.mm` 命名，短期支持，用于尝鲜新功能 |

⚠️ **重要提醒**：如果你还在用 MySQL 5.7 或 8.0，强烈建议尽快升级到 8.4 LTS，否则将面临安全风险。

---

### MySQL 8.4 LTS 核心新特性

作为当前生产环境推荐版本，8.4 LTS 带来多项重要改进：

- **InnoDB 并行查询**：默认开启，单条查询最大 4 个 worker 线程，复杂查询性能显著提升
- **Redo Log 在线动态调整**：无需重启即可调整容量，默认容量基于 CPU 核数自动计算
- **直方图自动更新**：优化器可自动重建统计信息，执行计划更精准
- **容器感知**：自动识别 Docker/K8s 环境，动态调整 `innodb_buffer_pool_instances` 和 `innodb_io_capacity`（默认提升至 10000，适配高速 SSD）
- **组复制（MGR）增强**：支持同大版本内小版本混跑及原地降级，克隆插件放宽版本限制

#### 重大变更（升级必看）

- **默认禁用 `mysql_native_password`**：改用 `caching_sha2_password`，旧版客户端需升级驱动或显式启用兼容模式
- **移除 MASTER/SLAVE 术语**：统一为 `SOURCE/REPLICA` 语法
- **多个 InnoDB 参数默认值调整**：`innodb_change_buffering` 从 `all` 改为 `none`，`innodb_adaptive_hash_index` 默认关闭，`innodb_io_capacity` 从 200 提升至 1000

---

### MySQL 9.7 LTS 核心新特性

新一代 LTS 版本引入了面向未来的能力：

- **AI 与向量支持**：原生 `VECTOR` 数据类型、HNSW 向量索引，支持 RAG 检索增强生成场景
- **Hypergraph 优化器**：默认启用，支持丛生树连接计划与 Hash Join，复杂查询优化时间减少 40%
- **PGO 编译优化**：TPC-C 基准测试性能提升约 15%
- **JSON Duality Views**：社区版开放，支持 DML 操作
- **OpenTelemetry 集成**：以 OTLP 格式输出日志、指标和追踪数据
- **彻底移除 `mysql_native_password`**

---

### 快速上手

#### 安装（以 Ubuntu 为例）

```bash
# 安装 MySQL 8.4
sudo apt update
sudo apt install mysql-server

# 启动并设置开机自启
sudo systemctl start mysql
sudo systemctl enable mysql

# 安全初始化（设置root密码、移除匿名用户等）
sudo mysql_secure_installation
```

#### 基本操作

```sql
-- 连接数据库
mysql -u root -p

-- 创建数据库
CREATE DATABASE mydb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建表
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 插入数据
INSERT INTO users (username, email) VALUES ('alice', 'alice@example.com');

-- 查询
SELECT * FROM users WHERE username = 'alice';
```

---

### 与 Python 项目集成

结合你之前了解的 FastAPI/Flask + Pydantic，MySQL 在 Python 项目中的典型集成方式：

#### 1. 驱动选择

| 驱动 | 特点 | 适用场景 |
|------|------|----------|
| **mysqlclient** | C 扩展，性能最好 | 传统同步项目（Flask/Django） |
| **PyMySQL** | 纯 Python，易安装 | 开发环境、无 C 编译环境 |
| **aiomysql** | 异步驱动 | FastAPI 异步项目 |
| **asyncmy** | 异步驱动，性能更优 | FastAPI 高并发场景 |

#### 2. ORM 框架

```python
# SQLAlchemy 2.0 + FastAPI 示例
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker
from datetime import datetime

DATABASE_URL = "mysql+aiomysql://user:password@localhost:3306/mydb"

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), nullable=False)
    created_at = Column(DateTime, default=datetime.now)

# 创建引擎和会话
engine = create_engine(DATABASE_URL, echo=True)
SessionLocal = sessionmaker(bind=engine)
```

#### 3. 结合 Pydantic 做数据校验

```python
from pydantic import BaseModel, EmailStr, Field

class UserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    email: EmailStr

class UserResponse(UserCreate):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True  # 兼容 SQLAlchemy ORM
```

---

### 索引优化最佳实践（2026 年版）

索引是查询性能的灵魂，以下是核心原则：

- **最左前缀原则**：复合索引 `(a, b, c)` 可匹配 `a`、`a+b`、`a+b+c` 查询，但不能单独匹配 `b` 或 `c`
- **覆盖索引**：查询字段全部在索引中，避免回表
- **选择性原则**：区分度高的列优先建索引（如身份证号），区分度低的列（如性别）不单独建
- **控制数量**：单表索引不超过 5 个，每增加 1 个索引写性能下降 7-12%
- **隐藏索引**：先创建 `INVISIBLE` 索引测试效果，确认有效后再转为 `VISIBLE`，降低变更风险
- **定期维护**：使用 `ANALYZE TABLE` 更新统计信息，`EXPLAIN` 分析执行计划

---

### 高可用架构方案

| 方案 | 特点 | 适用场景 |
|------|------|----------|
| **MGR（组复制）** | 基于 Paxos 协议，RPO=0，强一致 | 生产环境首选，至少 3 节点 |
| **Galera Cluster** | 多主写入，适合高并发写入 | 需处理写冲突 |
| **Orchestrator + 半同步复制** | 外部拓扑调度，大规模运维友好 | 大规模集群 |
| **云托管（RDS/PolarDB）** | 自动故障转移，秒级切换 | 资源有限、快速上线 |

⚠️ MHA 已停止维护，MMM 因脑裂风险已被淘汰。

---

### 性能调优核心参数

```ini
# my.cnf 核心配置
[mysqld]
# 缓冲池：建议设为物理内存的 60-70%
innodb_buffer_pool_size = 4G

# Redo Log：2026年建议 4-8GB
innodb_redo_log_capacity = 4G

# IO 能力：SSD 环境可设为 10000
innodb_io_capacity = 10000

# 最大连接数：根据应用服务器数量动态调整
max_connections = 500

# 慢查询日志
slow_query_log = ON
long_query_time = 1
```

---

### 与 PostgreSQL 对比

| 维度 | MySQL | PostgreSQL |
|------|-------|------------|
| **定位** | 简单高效，Web 应用首选 | 功能丰富，复杂查询/分析场景更强 |
| **并发模型** | 线程池，高并发读场景优秀 | 多进程，复杂查询并行能力强 |
| **JSON 支持** | 基础支持 | 更强大（JSONB 索引） |
| **生态** | 社区资源极丰富，云厂商支持完善 | 扩展生态强大（PostGIS/pgvector） |
| **适合场景** | 高并发 CRUD、读写分离、微服务 | 复杂事务、GIS、实时分析、AI 向量 |

---

### 学习路线建议

| 阶段 | 内容 | 时长 |
|------|------|------|
| 第一阶段 | SQL 基础语法、CRUD 操作、数据类型 | 1-2 周 |
| 第二阶段 | 索引原理、执行计划分析、慢查询优化 | 2-3 周 |
| 第三阶段 | 事务与锁机制、隔离级别、MVCC | 2-3 周 |
| 第四阶段 | 主从复制、读写分离、MGR 高可用 | 2-3 周 |
| 第五阶段 | 分库分表、性能调优、备份恢复策略 | 3-4 周 |
