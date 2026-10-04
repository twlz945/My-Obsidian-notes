---
title: Git
date: 2026-10-02
tags:
  - 工程化
  - Git
aliases:
  - 版本控制
related:
  - "[[单元测试]]"
  - "[[../教程/python/用 Python 搭建复杂项目]]"
---

# Git

Git 是分布式版本控制系统，记录代码的每一次变化，让「敢改代码」成为可能。`学习规划` 把它列为两条游戏路线的通用工程能力：分支、提交、回滚是一切协作与实验的前提。

## 核心要点

- **快照而非差异**：每次提交是完整项目状态的一个快照。
- **本地全量**：仓库包含完整历史，可离线提交。
- **分支极轻**：鼓励用分支隔离实验与功能。
- **三区模型**：工作区 → 暂存区（`git add`）→ 版本库（`git commit`）。

## 常用命令

| 命令 | 作用 |
| ---- | ---- |
| `git init` | 初始化仓库 |
| `git clone <url>` | 克隆远程仓库 |
| `git status` | 查看改动状态 |
| `git add <file>` | 暂存改动 |
| `git commit -m "msg"` | 提交 |
| `git log --oneline --graph` | 查看历史 |
| `git diff` | 查看未暂存差异 |
| `git switch -c feature/x` | 新建并切换分支 |
| `git merge feature/x` | 合并分支 |
| `git revert <commit>` | 生成一次反向提交（安全回滚） |
| `git reset --hard <commit>` | 丢弃改动（危险） |

## 推荐工作流

```bash
git switch main
git pull                          # 同步远程
git switch -c feat/bignum         # 从 main 开功能分支
# …开发与提交…
git switch main
git merge --no-ff feat/bignum     # 保留分支记录
git push origin main
```

- **小步提交**：一次提交只做一件事，信息用祈使句（如 `add offline progress`）。
- **分支对应里程碑**：游戏项目可按 M1/M2 开分支，完成后合并。
- **`.gitignore`**：忽略 `node_modules/`、`dist/`、`.env`、构建缓存与本地存档。

## 回滚策略

| 场景 | 推荐 |
| ---- | ---- |
| 撤销未提交改动 | `git restore <file>` |
| 修改最近一次提交 | `git commit --amend` |
| 已推送的历史错误 | `git revert`（不改写历史） |
| 本地实验失败 | 切回分支 / `git reset` |

## 相关笔记

- [[单元测试]] — 提交前自动跑的保障
- [[../教程/python/用 Python 搭建复杂项目]] — 工程实践中的版本控制
- [[学习规划|游戏开发学习规划]] — 通用工程能力
