---
title: FastAPI
date: 2026-09-26
tags:
  - Python
  - FastAPI
  - 后端开发
---

# FastAPI

## FastAPI 是什么？

FastAPI 是一个基于 Python 类型提示的现代高性能 Web 框架，底层依托 **Starlette**（异步 ASGI 框架）和 [[Pydantic]]（数据校验库）。核心定位是"为 API 而生"，专为构建 RESTful API、微服务和 AI 推理服务设计。

## 核心优势

- **极致性能**：原生支持 `async/await` 异步编程，纯接口场景 QPS 可达 15,000 ~ 20,000，约为 Flask 的 3 ~ 5 倍，性能接近 Go 和 Node.js。
- **类型安全**：利用 Python 类型注解实现自动数据校验、序列化和 IDE 补全，人为错误减少约 40%。
- **自动文档**：零配置自动生成符合 OpenAPI 标准的交互式文档，内置 Swagger UI（`/docs`）和 ReDoc（`/redoc`），文档与代码实时同步。
- **依赖注入系统**：内置声明式 `Depends` 机制，支持数据库会话、认证权限等逻辑的复用、嵌套与自动缓存。
- **开发效率**：开发速度提升约 200%~300%，样板代码减少约 60%~70%。

## 快速上手示例

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def read_root():
    return {"message": "Hello, FastAPI!"}

@app.get("/items/{item_id}")
async def read_item(item_id: int, q: str = None):
    return {"item_id": item_id, "q": q}
```

启动服务（开发模式，自动热重载）：

```bash
fastapi dev main.py
# 或
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

访问 `http://127.0.0.1:8000/docs` 即可看到自动生成的交互式 API 文档。

## 企业级项目架构

FastAPI 项目推荐采用**分层解耦**架构，与你之前看到的 `src` 布局完全契合：

```text
project_root/
├── src/
│   └── your_package/
│       ├── main.py           # 入口：初始化 FastAPI、注册路由/中间件
│       ├── core/             # 核心配置层：环境变量、安全认证、全局异常
│       ├── api/              # 路由层：HTTP 请求接收与响应返回
│       ├── schemas/          # 数据契约层：Pydantic 请求/响应模型
│       ├── models/           # 数据库模型层：SQLAlchemy ORM 表结构
│       ├── services/         # 业务逻辑层：核心流程编排
│       ├── repositories/     # 数据访问层：封装 CRUD 操作
│       └── utils/            # 通用工具层
├── tests/
├── pyproject.toml
└── .env
```

关键原则：

- **路由层**只负责接收请求、参数校验、调用服务层、返回响应，不含业务逻辑
- **服务层**承载核心业务编排，不依赖 HTTP 框架对象
- **仓储层**专门负责数据库交互，执行 CRUD
- **Schema 层**严格区分输入模型（Create/Update）与输出模型（Response），防止敏感字段泄露

## 学习路线建议（约 10 周）

|阶段|内容|时长|
|---|---|---|
|第一阶段|基础语法、环境搭建、路由与参数|1-2 周|
|第二阶段|Pydantic 数据校验、响应控制、接口设计|2-3 周|
|第三阶段|分层架构、依赖注入、安全认证、异步数据库|2-3 周|
|第四阶段|WebSocket、Redis 缓存、自动化测试、日志规范|2-3 周|
|第五阶段|Docker 部署、Nginx 反向代理、性能调优|3-4 周|

## 适用场景

- **高并发 API 服务**：电商、社交、即时通讯等 IO 密集型场景
- **微服务架构**：轻量、高性能，适合服务拆分
- **AI 推理服务**：大模型流式输出（SSE）、GPU 推理接口封装
- **前后端分离项目**：作为纯后端 API 网关

## 与 Django / Flask 对比

| 维度   | FastAPI           | Django                 | Flask       |
| ---- | ----------------- | ---------------------- | ----------- |
| 性能   | ⭐⭐⭐⭐⭐             | ⭐⭐                     | ⭐⭐⭐         |
| 异步支持 | 原生                | 3.1+ 部分支持              | 需扩展         |
| 开箱即用 | 中等（需自组装 ORM/认证）   | 极强（Admin/ORM/Auth 全内置） | 弱（需大量插件）    |
| 自动文档 | ✅ 内置              | ❌ 需插件                  | ❌ 需插件       |
| 适合场景 | 高并发 API、微服务、AI 服务 | 大型单体后台、SaaS 平台         | 轻量工具、高度定制项目 |
|      |                   |                        |             |
#网络编程 #Python 