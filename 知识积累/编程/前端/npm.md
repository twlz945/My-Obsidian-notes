---
title: npm
date: 2026-10-02
tags:
  - 前端
  - JavaScript
  - Node.js
aliases:
  - Node Package Manager
  - 包管理
related:
  - "[[Node.js]]"
  - "[[前端工程化]]"
  - "[[Express]]"
---

# npm

npm（Node Package Manager）是 [[Node.js]] 自带的包管理器，也是全球最大的开源软件仓库。它负责安装依赖、运行脚本、发布包，是 JS/TS 项目的入口工具。

## 核心要点

- **依赖清单 `package.json`**：记录项目元信息、依赖与脚本。
- **锁文件 `package-lock.json`**：锁定依赖的精确版本，保证团队安装结果一致。
- **`node_modules/`**：依赖实际安装目录，通常加入 `.gitignore`。
- **`npx`**：临时执行包提供的命令，无需全局安装。

## 常用命令

| 命令 | 作用 |
| ---- | ---- |
| `npm init -y` | 初始化 `package.json` |
| `npm install` | 安装 `package.json` 中全部依赖 |
| `npm install <pkg>` | 安装到 `dependencies` |
| `npm install -D <pkg>` | 安装到 `devDependencies` |
| `npm uninstall <pkg>` | 卸载依赖 |
| `npm update` | 按 semver 升级依赖 |
| `npm run <script>` | 执行 `scripts` 中的脚本 |
| `npm ls` | 查看依赖树 |
| `npm ci` | 按锁文件干净安装，适合 CI |
| `npx <cmd>` | 临时执行包命令 |

## package.json 结构

```jsonc
{
  "name": "my-app",
  "version": "0.1.0",
  "type": "module",              // 使用 ESM
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "test": "vitest"
  },
  "dependencies": {
    "express": "^4.19.0"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "vite": "^5.3.0"
  }
}
```

## 语义化版本（semver）

版本号形如 `主版本.次版本.补丁`，前缀决定可升级范围：

| 写法 | 允许升级 | 说明 |
| ---- | -------- | ---- |
| `1.2.3` | 不升级 | 固定版本 |
| `~1.2.3` | 补丁 | `>=1.2.3 <1.3.0` |
| `^1.2.3` | 次版本+补丁 | `>=1.2.3 <2.0.0`（默认） |
| `*` / `latest` | 任意 | 不推荐，结果不可复现 |

> [!warning] 待确认：主版本升级可能含破坏性变更，升级前先看 changelog。

## 其他包管理器

| 工具 | 特点 |
| ---- | ---- |
| npm | 官方自带，生态最全 |
| pnpm | 硬链接共享依赖，省磁盘、装得快 |
| yarn | 早期替代品，现多为 Yarn Berry |

游戏开发路线 A 建议直接使用 pnpm 或 npm，配合 Vite，参见 [[学习规划|游戏开发学习规划]]。

## 相关笔记

- [[Node.js]] — npm 的运行环境
- [[前端工程化]] — 依赖管理在工具链中的位置
- [[TypeScript]] — 通过 npm 安装的类型工具
- [[Express]] — 典型的 npm 依赖
- [[编程]] — 编程知识目录导航

## 参考来源

- [npm 官方文档](https://docs.npmjs.com/)
- [Semantic Versioning](https://semver.org/lang/zh-CN/)
