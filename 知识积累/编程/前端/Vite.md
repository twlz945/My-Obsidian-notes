---
title: Vite
date: 2026-10-02
tags:
  - 前端
  - 工程化
aliases:
  - Vite.js
related:
  - "[[前端工程化]]"
  - "[[npm]]"
  - "[[Vitest]]"
---

# Vite

Vite 是新一代前端构建工具：开发时基于原生 ESM 提供**秒级启动 + 热更新（HMR）**，生产构建默认用 Rollup 打包。它是 [[前端工程化]] 中「开发服务器 + 打包器」的组合体，游戏开发路线 A 的技术栈之一。

## 核心要点

- **开发不打包**：浏览器直接按 ESM 请求模块，Vite 只按需转换，冷启动快。
- **HMR 快**：改动单个模块只热替换该模块，状态尽量保留。
- **生产用 Rollup**：输出经过 tree-shaking、压缩、代码分割的产物。
- **开箱即用**：原生支持 [[TypeScript]]、CSS 预处理器、静态资源与 `.env`。

## 快速开始

```bash
npm create vite@latest my-app -- --template vanilla-ts
cd my-app
npm install
npm run dev      # 开发服务器，默认 http://localhost:5173
npm run build    # 生产构建，输出 dist/
npm run preview  # 本地预览 dist/
```

> [!tip] 模板
> `vanilla-ts` 适合纯 DOM/CSS 的放置游戏；`react-ts`、`vue-ts` 等用于框架项目。

## 配置文件

```typescript
// vite.config.ts
import { defineConfig } from "vite";

export default defineConfig({
  base: "./",                 // 部署到子路径时使用
  server: {
    port: 5173,
    proxy: {
      "/api": "http://localhost:3000", // 开发代理，避免跨域
    },
  },
  build: {
    target: "es2022",
    sourcemap: true,
  },
});
```

## 环境变量

只有以 `VITE_` 开头的变量会暴露给客户端：

```bash
# .env
VITE_API_BASE=/api
```

```typescript
console.log(import.meta.env.VITE_API_BASE);
```

> [!warning] 待确认：任何打进前端的变量都会公开，密钥类信息绝不能放在 `VITE_` 变量里。

## 与 Webpack 对比

| 维度 | Vite | Webpack |
| ---- | ---- | ------- |
| 开发启动 | 原生 ESM，按需编译，秒级 | 先打包再启动，较慢 |
| 配置复杂度 | 低，约定优先 | 高，插件生态庞大 |
| 生产打包 | Rollup | Webpack |
| 适用 | 新项目、Vue/React/纯 TS | 老项目、复杂自定义构建 |

## 相关笔记

- [[前端工程化]] — Vite 在工具链中的位置
- [[npm]] — 安装与脚本
- [[Vitest]] — 与 Vite 共享配置的测试框架
- [[TypeScript]] — 内置支持
- [[学习规划|游戏开发学习规划]] — 路线 A 技术栈

## 参考来源

- [Vite 官方文档](https://vite.dev/)
