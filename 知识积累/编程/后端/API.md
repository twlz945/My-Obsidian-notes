---
title: API
date: 2026-10-02
tags:
  - 后端开发
  - 网络编程
aliases:
  - Application Programming Interface
  - 应用程序接口
related:
  - "[[FastAPI]]"
  - "[[网络]]"
  - "[[JSON]]"
---

# API

API（Application Programming Interface，应用程序编程接口）是软件之间约定好的交互方式：调用方只需知道「怎么调用」，无需了解内部实现。它既是代码层面的函数/类接口，也是网络层面的服务契约。

## 核心要点

- **接口即契约**：API 规定输入、输出、错误和行为，实现可以随时替换而不影响调用方。
- **抽象与解耦**：隐藏内部复杂度，是 [[依赖注入]]、分层架构能成立的基础。
- **两种常见语境**：库/SDK 的编程接口（如 [[Socket]]），以及网络服务的 HTTP 接口（如 [[FastAPI]] 提供的 RESTful API）。

## API 的层次

| 层次 | 含义 | 例子 |
| ---- | ---- | ---- |
| 语言/库 API | 函数、类、模块暴露的调用入口 | Python 标准库、`socket` 模块 |
| 操作系统 API | 系统调用封装 | 文件读写、线程创建 |
| 网络 API | 跨进程/跨主机的服务契约 | REST、RPC、GraphQL |

## Web API 常见风格

| 风格 | 特点 | 典型场景 |
| ---- | ---- | ---- |
| REST | 以资源为中心，用 HTTP 方法表达操作，无状态 | 通用后端接口、微服务 |
| RPC（gRPC 等） | 像调用本地函数一样调用远程方法，性能高 | 内部服务通信、强类型契约 |
| GraphQL | 客户端按需声明字段，一次请求取回所需数据 | 前端灵活取数、聚合查询 |
| WebSocket | 全双工长连接，服务端可主动推送 | 聊天、实时通知 |

## RESTful API 速览

REST 用 URL 表示资源、用 HTTP 方法表示动作：

```http
GET    /users        # 获取用户列表
GET    /users/1      # 获取单个用户
POST   /users        # 创建用户
PUT    /users/1      # 整体更新用户
PATCH  /users/1      # 部分更新用户
DELETE /users/1      # 删除用户
```

常见状态码：

| 状态码 | 含义 |
| ------ | ---- |
| 200 / 201 | 成功 / 创建成功 |
| 204 | 成功但无返回内容 |
| 400 / 422 | 请求参数错误 / 校验失败 |
| 401 / 403 | 未认证 / 无权限 |
| 404 / 409 | 资源不存在 / 冲突 |
| 500 / 502 | 服务端错误 / 网关错误 |

请求与响应体通常使用 [[JSON]] 交换数据，字段校验与序列化可交给 [[Pydantic]] 处理。

## 一个最小示例

```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class User(BaseModel):
    name: str
    age: int

@app.post("/users", status_code=201)
def create_user(user: User):
    return {"id": 1, **user.model_dump()}
```

## 设计要点

- **面向资源命名**：URL 用名词复数（`/users`），动作交给 HTTP 方法，不要写成 `/getUser`。
- **统一响应结构**：约定错误格式（如 `{"code": ..., "message": ...}`），便于客户端处理。
- **版本管理**：通过 `/v1/` 路径或请求头区分版本，避免破坏性变更影响旧客户端。
- **认证与鉴权**：常用 Token（JWT）、OAuth2、API Key；认证解决「你是谁」，鉴权解决「你能做什么」。
- **幂等性**：GET/PUT/DELETE 应可安全重试，POST 通常非幂等，可用幂等键去重。
- **限流与分页**：对列表接口提供 `page`/`limit` 或游标分页；对高频接口做速率限制。
- **文档化**：用 OpenAPI/Swagger 描述契约，[[FastAPI]] 可自动生成交互式文档。

## 相关笔记

- [[FastAPI]] — 用 Python 快速构建 RESTful API
- [[Flask]] — 另一种 Python Web 框架，可开发 API
- [[Pydantic]] — 请求/响应数据的校验与序列化
- [[JSON]] — Web API 常用的数据交换格式
- [[Socket]] — 更底层的网络编程接口
- [[TCP]] / [[UDP]] — API 通信依赖的传输层协议
- [[网络]] — 网络编程目录导航

## 参考来源

- [MDN: Web APIs](https://developer.mozilla.org/zh-CN/docs/Web/API)
- [RFC 9110: HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110)
