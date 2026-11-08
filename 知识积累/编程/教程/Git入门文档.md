---
title: Git 入门文档
date: 2026-11-01
tags:
  - Git
  - 工程化
  - 教程
aliases:
  - Git入门
  - Git 教程
related:
  - "[[Git]]"
  - "[[教程]]"
  - "[[架构与工程]]"
  - "[[用 Python 搭建复杂项目]]"
---

# Git 入门文档

Git 是分布式版本控制系统：它把项目每一次提交保存成**完整快照**，让你可以放心改代码、随时回到任意历史版本、并和他人并行开发。这篇文档从零开始，覆盖安装配置、日常提交流程、分支协作、撤销回滚与常见坑。概念速览见 [[Git]]。

## 核心要点

- **快照而非差异**：每次提交是当时项目状态的一个快照，历史就是快照链。
- **本地全量仓库**：提交、查看历史、切换分支都能离线完成；远程只是另一个副本。
- **三区模型**：工作区 → 暂存区（`git add`）→ 版本库（`git commit`）。
- **分支是极轻的指针**：新建分支几乎零成本，鼓励用分支隔离功能与实验。

## 一、安装与初次配置

安装后先确认版本，再设置身份——每次提交都会记录这两项：

```bash
git --version

git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main   # 新仓库默认分支名
git config --global core.autocrlf true        # Windows 上处理换行符
git config --list                             # 查看全部配置
```

| 层级 | 命令参数 | 作用范围 |
| ---- | -------- | -------- |
| 系统 | `--system` | 本机所有用户 |
| 全局 | `--global` | 当前用户的所有仓库 |
| 仓库 | `--local`（默认） | 仅当前仓库 |

> [!tip] 公司仓库和个人仓库邮箱不同时，用 `--local` 在单个仓库里覆盖全局配置。

## 二、三个区域与文件状态

```text
工作区 (Working Directory)
   │  git add
   ▼
暂存区 (Staging Area / index)
   │  git commit
   ▼
版本库 (Repository, .git)
   │  git push
   ▼
远程仓库 (Remote)
```

文件在 Git 眼里只有几种状态：

| 状态 | 含义 | 常用命令 |
| ---- | ---- | -------- |
| untracked | 新文件，Git 还没跟踪 | `git add` |
| modified | 已跟踪但工作区有改动 | `git add` / `git restore` |
| staged | 改动已进暂存区，等待提交 | `git commit` |
| committed | 已写入版本库 | `git log` |

`git status` 是最常用的命令，它会告诉你每个文件当前处在哪一步。

## 三、日常基本流程

```bash
git init                        # 在项目目录初始化仓库
git status                      # 看当前状态
git add index.html              # 暂存单个文件
git add .                       # 暂存当前目录全部改动
git commit -m "add landing page"
git log --oneline --graph --all # 图形化查看历史
git diff                        # 工作区 vs 暂存区
git diff --staged               # 暂存区 vs 最近一次提交
```

| 命令 | 作用 |
| ---- | ---- |
| `git init` | 初始化本地仓库 |
| `git clone <url>` | 克隆远程仓库（自带 remote 与历史） |
| `git add <path>` | 暂存改动 |
| `git commit -m "msg"` | 提交暂存区内容 |
| `git commit --amend` | 修改最近一次提交（信息或内容） |
| `git log --oneline` | 简洁历史 |
| `git show <commit>` | 查看某次提交的具体改动 |

> [!warning] `git add .` 会暂存所有改动，包括误提交的临时文件。提交前先 `git status` 过一眼。

## 四、分支与合并

分支本质上是指向某个提交的可移动指针，`HEAD` 指向当前所在分支。

```bash
git branch                     # 列出本地分支
git switch -c feat/login       # 新建并切换到 feat/login
git switch main                # 切回 main
git merge feat/login           # 把 feat/login 合进当前分支
git branch -d feat/login       # 删除已合并分支
```

| 操作 | 命令 | 说明 |
| ---- | ---- | ---- |
| 新建并切换 | `git switch -c <name>` | 旧写法 `git checkout -b` |
| 切换 | `git switch <name>` | 旧写法 `git checkout <name>` |
| 合并 | `git merge <branch>` | 默认快进合并 |
| 保留分支记录 | `git merge --no-ff <branch>` | 多一个合并提交，历史更清晰 |
| 变基 | `git rebase main` | 把当前分支提交挪到 main 之后，历史线性 |

### 解决冲突

合并冲突时 Git 会在文件里插入标记：

```text
<<<<<<< HEAD
当前分支的内容
=======
被合入分支的内容
>>>>>>> feat/login
```

处理步骤：手动改成想要的结果 → 删除标记 → `git add <file>` → `git commit`。想放弃这次合并用 `git merge --abort`。

> [!tip] 只在自己尚未推送的分支上 rebase；对已共享的历史 rebase 会让别人的仓库错乱。

## 五、远程仓库协作

```bash
git remote add origin git@github.com:user/repo.git
git remote -v                     # 查看远程地址
git push -u origin main           # 首次推送并建立跟踪关系
git fetch origin                  # 只下载远程更新，不改工作区
git pull                          # fetch + merge（或 rebase）
git push                          # 推送当前分支
```

典型协作循环：

1. `git switch main` + `git pull` 同步最新代码。
2. `git switch -c feat/xxx` 开功能分支开发，小步提交。
3. `git push -u origin feat/xxx` 推送到远程。
4. 在平台上发起 Pull Request / Merge Request，评审后合并。
5. 删除本地与远程的功能分支。

`pull` 与 `fetch` 的区别：`fetch` 只更新远程跟踪分支（如 `origin/main`），安全；`pull` 会立刻合并进当前分支，可能产生冲突。

## 六、撤销与回滚

| 场景 | 命令 | 是否改写历史 |
| ---- | ---- | ------------ |
| 撤销工作区改动 | `git restore <file>` | 否 |
| 取消暂存 | `git restore --staged <file>` | 否 |
| 修改最近一次提交 | `git commit --amend` | 是（仅限未推送） |
| 撤销某次提交（生成反向提交） | `git revert <commit>` | 否，安全 |
| 回退到某个提交并丢弃之后改动 | `git reset --hard <commit>` | 是，危险 |
| 找回误删的提交 | `git reflog` | — |

> [!warning] `git reset --hard` 会永久丢弃未提交的改动。已推送的历史出错时用 `git revert`，不要 `reset` 后强推。

`git reflog` 记录 HEAD 的每一次移动，是本地误操作的后悔药：找到目标提交哈希后 `git reset --hard <hash>` 即可恢复。

## 七、.gitignore 与提交规范

`.gitignore` 放在仓库根目录，按行匹配，`#` 开头为注释：

```gitignore
# 依赖与构建产物
node_modules/
dist/
__pycache__/
*.pyc

# 环境与密钥
.env
*.local

# 编辑器与系统文件
.vscode/
.DS_Store
```

规则要点：

- `/build` 只忽略根目录的 `build`，`build/` 忽略任意层级的该目录。
- `!important.log` 用感叹号做例外。
- 已被跟踪的文件加进 `.gitignore` 不会自动取消跟踪，需要 `git rm --cached <file>`。

提交信息建议用祈使句、说明「做了什么」，需要更严格时采用 Conventional Commits：

```text
feat: 支持离线模式下的进度保存
fix: 修复关卡切换时坐标越界
docs: 补充构建步骤说明
```

## 八、常见坑

| 现象 | 原因 | 建议 |
| ---- | ---- | ---- |
| 提交里出现一堆依赖文件 | 没有 `.gitignore` 或先 add 了 | 先写 `.gitignore`，必要时 `git rm --cached` |
| 换行符整文件改动 | Windows/Linux 换行差异 | 统一 `core.autocrlf`，或加 `.gitattributes` |
| 误提交密钥 | 提交前没检查 | 立即在平台作废密钥；历史清洗用 `git filter-repo` |
| 合并后代码不见了 | 冲突时误删标记内内容 | 用 `git merge --abort` 重来，或对照 `git diff` |
| 推送被拒（non-fast-forward） | 远程有新提交 | 先 `git pull --rebase` 再推 |
| 分支名大小写混乱 | 文件系统不区分大小写 | 团队统一用 `feat/`、`fix/` 前缀 |

## 九、学习路线与练习

| 阶段 | 内容 | 练习 |
| ---- | ---- | ---- |
| 入门 | 配置、三区、add/commit/log | 把一个小脚本目录变成仓库并提交三次 |
| 进阶 | 分支、合并、冲突 | 开两条分支改同一文件，手动解决冲突 |
| 协作 | 远程、PR、fetch/pull | 在 GitHub 建仓库，走一遍 PR 流程 |
| 进阶技巧 | rebase、reflog、reset/revert | 故意 `reset --hard` 后用 reflog 找回 |

## 相关笔记

- [[Git]] — 概念速览与常用命令表
- [[架构与工程]] — 工程化能力目录
- [[单元测试]] — 提交前自动运行的保障
- [[用 Python 搭建复杂项目]] — 工程实践中的版本控制
- [[教程]] — 教程目录导航

## 参考来源

- [Pro Git 中文版](https://git-scm.com/book/zh/v2)
- [Git 官方文档](https://git-scm.com/docs)
- [Conventional Commits](https://www.conventionalcommits.org/zh-hans/)
