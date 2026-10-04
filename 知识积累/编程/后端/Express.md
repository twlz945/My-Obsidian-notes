---
title: Express
date: 2026-10-02
tags:
  - 后端开发
  - 网络编程
  - Node.js
aliases:
  - Express.js
related:
  - "[[Node.js]]"
  - "[[API]]"
  - "[[FastAPI]]"
---

# Express

Express 是 [[Node.js]] 上最流行的极简 Web 框架，核心理念是**路由 + 中间件**：请求依次穿过一串函数，最终生成响应。它不强制目录结构，适合快速搭建 [[API]] 和 Web 服务。

## 核心要点

- **轻量、无侵入**：只提供路由与中间件机制，其余自行组合。
- **中间件模型**：每个中间件形如 `(req, res, next)`，可修改请求、结束响应或交给下一个。
- **生态成熟**：模板、静态资源、鉴权、CORS 等都有现成中间件。
- **与 Python 对照**：思想接近 [[Flask]]，而 [[FastAPI]] 自带校验与文档；Express 需自行引入。

## 最小示例

```javascript
import express from "express";

const app = express();
app.use(express.json()); // 解析 JSON 请求体

app.get("/", (req, res) => {
  res.json({ message: "Hello, Express!" });
});

app.get("/users/:id", (req, res) => {
  const { id } = req.params;
  const { page } = req.query; // /users/1?page=2
  res.json({ id, page: page ?? 1 });
});

app.listen(3000, () => console.log("http://localhost:3000"));
```

## 路由

```javascript
import { Router } from "express";
const router = Router();

router.get("/", listUsers);
router.post("/", createUser);
router.put("/:id", updateUser);
router.delete("/:id", deleteUser);

app.use("/api/users", router); // 挂载到子路径
```

- 路径参数：`req.params`；查询串：`req.query`；请求体：`req.body`。
- 响应：`res.json()`、`res.status(201).send()`、`res.redirect()`。

## 中间件

```javascript
// 日志中间件
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next(); // 交给下一个中间件
});

// 仅作用于某路径
app.use("/admin", authMiddleware);
```

中间件顺序很重要：先注册的先生效，错误处理中间件必须带 4 个参数并放在最后。

```javascript
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ message: "Internal Server Error" });
});
```

## 与 TypeScript 配合

```bash
npm install express
npm install -D typescript @types/express
```

```typescript
import express, { type Request, type Response } from "express";
const app = express();

app.get("/health", (_req: Request, res: Response) => {
  res.json({ ok: true });
});
```

## 对比其他 Node 框架

| 框架 | 特点 | 场景 |
| ---- | ---- | ---- |
| Express | 极简、中间件生态最大 | 通用服务、快速原型 |
| Koa | 基于 async/await，更轻 | 需要精细控制流程 |
| Fastify | 高性能、内置 Schema 校验 | 高吞吐接口 |
| NestJS | 模块化 + 依赖注入，类 Spring | 大型企业级应用 |

## 相关笔记

- [[Node.js]] — Express 的运行环境
- [[API]] — RESTful 接口设计要点
- [[npm]] — 安装 Express 与类型声明
- [[TypeScript]] — 为 Express 增加静态类型
- [[FastAPI]] / [[Flask]] — Python 侧的对等框架
- [[网络]] — 网络编程目录导航

## 参考来源

- [Express 官方文档](https://expressjs.com/)
- [Express 中文文档](https://expressjs.com/zh-cn/)
