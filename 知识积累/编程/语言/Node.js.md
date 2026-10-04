---
title: Node.js
date: 2026-10-02
tags:
  - 后端开发
  - Node.js
  - JavaScript
aliases:
  - NodeJS
  - Node
related:
  - "[[JavaScript]]"
  - "[[API]]"
  - "[[JSON]]"
---

# Node.js

Node.js 是基于 Chrome V8 引擎的 [[JavaScript]] 运行时，让 JS 脱离浏览器在服务端执行。它以「非阻塞 I/O + 事件循环」著称，适合高并发的 I/O 密集型服务。

## 核心要点

- **事件驱动、非阻塞 I/O**：单线程主循环 + 回调/异步，避免线程阻塞，天然适合网络服务。
- **npm 生态**：全球最大的开源包仓库，`package.json` 管理依赖与脚本。
- **同语言全栈**：前后端都用 JS，可共享类型与工具链。
- **不只是后端**：命令行工具、构建工具、桌面应用（Electron）都能用。

## 运行与模块

```bash
node app.js        # 运行脚本
node --version     # 查看版本
npm init -y        # 初始化 package.json
npm install express
npm run dev        # 执行 package.json 里的脚本
```

模块系统：

```javascript
// ESM（推荐）
import { readFile } from "node:fs/promises";

// CommonJS（历史写法）
const fs = require("node:fs");
```

## 常用内置模块

| 模块 | 用途 |
| ---- | ---- |
| `node:fs` | 文件读写 |
| `node:path` | 路径拼接与解析 |
| `node:http` | 创建 HTTP 服务 |
| `node:events` | 事件发射器 |
| `node:stream` | 流式处理大文件/数据 |
| `node:crypto` | 加密、哈希、随机数 |

最小 HTTP 服务：

```javascript
import http from "node:http";

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ ok: true }));
});

server.listen(3000, () => console.log("http://localhost:3000"));
```

## 生态与框架

| 框架 | 特点 | 场景 |
| ---- | ---- | ---- |
| Express | 极简、中间件生态成熟 | 通用 Web 服务、[[API]] |
| Koa | 更轻，基于 async/await | 需要精细控制中间件 |
| NestJS | 内置依赖注入、模块化，类 Spring | 大型企业级应用 |
| Fastify | 性能高、Schema 校验 | 高吞吐接口 |

## 事件循环与并发

Node 的 libuv 负责异步 I/O，主线程通过事件循环调度回调：

- **微任务**：Promise、`process.nextTick`，优先执行。
- **宏任务阶段**：timers → I/O callbacks → poll → check → close。
- **CPU 密集任务**：用 `worker_threads` 或多进程 `cluster`，否则会阻塞主线程。

```javascript
import { Worker } from "node:worker_threads";
const worker = new Worker("./heavy.js");
```

## 与 Python 后端对比

| 维度 | Node.js | Python（[[FastAPI]] / [[Flask]]） |
| ---- | ---- | ---- |
| 并发模型 | 事件循环 + 非阻塞 I/O | 异步（asyncio）或多进程 |
| 语言风格 | 单一 JS，前端可复用 | 语法直观，数据科学生态强 |
| 包管理 | npm / pnpm / yarn | pip / uv / poetry |
| 典型场景 | 实时通信、BFF、API 网关 | 数据处理、AI、通用后端 |

## 相关笔记

- [[JavaScript]] — Node.js 使用的编程语言
- [[API]] — 用 Node.js 构建 RESTful 接口
- [[JSON]] — Node 服务常用的数据格式
- [[编程]] — 编程知识目录导航

## 参考来源

- [Node.js 官方文档](https://nodejs.org/zh-cn/docs)
- [npm 官方文档](https://docs.npmjs.com/)
