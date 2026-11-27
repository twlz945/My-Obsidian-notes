---
title: Git 完整指令文档
date: 2026-11-08
tags:
  - Git
  - 工程化
aliases:
  - Git 命令速查
  - Git Cheat Sheet
related:
  - "[[Git]]"
  - "[[Git入门文档]]"
  - "[[架构与工程]]"
---

# Git 完整指令文档

按用途分类的 Git 命令参考。概念与操作教程见 [[Git]] 和 [[Git入门文档]]，本篇只做查询：需要时按分类找到命令，再看参数。

## 阅读说明

| 写法 | 含义 |
| ---- | ---- |
| `<path>` | 必填参数 |
| `[<path>]` | 可选参数 |
| `...` | 可接多个同类参数 |
| `A \| B` | 二选一 |
| `--[no-]xxx` | 开启 / 关闭同一开关 |

通用约定：

- 大多数命令支持 `-h` 与 `--help`，完整手册用 `git help <command>` 或 `git <command> --help`。
- `--` 之后的参数一律按路径解释，可避免文件名与分支名歧义：`git checkout -- <file>`。
- 输出过长时按 `q` 退出分页器，`git --no-pager <command>` 可禁用分页。

## 一、配置与帮助

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global core.editor "code --wait"
git config --global core.autocrlf true     # Windows
git config --list --show-origin           # 列出配置及其来源文件
git config --get <key>
git config --unset <key>
git config --global --edit                 # 直接编辑配置文件
```

| 范围 | 参数 | 影响 |
| ---- | ---- | ---- |
| 系统 | `--system` | 本机所有用户 |
| 全局 | `--global` | 当前用户的所有仓库 |
| 仓库 | `--local` | 当前仓库（默认） |
| 临时 | `-c key=value` | 仅本次命令，如 `git -c core.pager=cat log` |

常用别名，减少重复输入：

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.last "log -1 HEAD --stat"
```

| 命令 | 作用 |
| ---- | ---- |
| `git help <cmd>` | 打开完整手册 |
| `git <cmd> -h` | 简短用法 |
| `git --version` | 查看版本 |
| `git version --build-options` | 编译选项（可确认 `+clipboard`、`+ssh` 等） |

## 二、创建与克隆

```bash
git init                      # 当前目录初始化
git init <dir>                # 新建目录并初始化
git init --bare <repo>.git    # 裸仓库，用作服务端
git clone <url>               # 克隆到同名目录
git clone <url> <dir>         # 指定目录名
git clone --depth 1 <url>     # 浅克隆，只取最近一次提交
git clone --branch <tag|branch> <url>
git clone --recurse-submodules <url>
```

| 参数 | 作用 |
| ---- | ---- |
| `--bare` | 无工作区，只存版本库 |
| `--mirror` | 镜像所有引用，用于完整备份 |
| `--depth <n>` | 浅克隆深度 |
| `--single-branch` | 只取一个分支 |
| `--filter=blob:none` | 部分克隆，按需下载文件内容 |

## 三、日常提交

```bash
git status                     # 完整状态
git status -sb                 # 精简 + 分支信息
git add <path>                 # 暂存指定文件
git add -A                     # 暂存全部改动（含删除）
git add -u                     # 只暂存已跟踪文件的改动
git add -p                     # 按块挑选暂存
git commit -m "message"
git commit -am "message"       # 跳过 add（仅已跟踪文件）
git commit --amend             # 修改最近一次提交
git commit --amend --no-edit   # 保留原提交信息
git commit --allow-empty -m "ci: trigger"
```

| 命令 | 作用 |
| ---- | ---- |
| `git diff` | 工作区 vs 暂存区 |
| `git diff --staged` | 暂存区 vs 最近提交（同 `--cached`） |
| `git diff <a> <b>` | 两个提交 / 分支之间 |
| `git diff --stat` | 只显示改动统计 |
| `git show <commit>` | 查看某次提交内容 |
| `git rm <file>` | 删除并暂存 |
| `git rm --cached <file>` | 停止跟踪但保留本地文件 |
| `git mv <old> <new>` | 移动 / 重命名并暂存 |

> [!warning] `git commit -a` 不会包含新文件；新文件必须先 `git add`。

## 四、历史查看

```bash
git log
git log --oneline --graph --decorate --all
git log -n 5                          # 最近 5 条
git log --author="Name" --since="2 weeks ago"
git log -- <path>                     # 某文件的提交历史
git log -S "functionName"             # 搜索增删过该字符串的提交
git log --grep="fix"                  # 按提交信息搜索
git log -p                            # 附带补丁
git log --follow -- <file>            # 跟踪重命名前的历史
```

自定义格式：

```bash
git log --pretty=format:"%h %ad %an %s" --date=short
git shortlog -sn                      # 按作者统计提交数
git blame <file>                      # 逐行显示最后修改者
git blame -L 10,20 <file>             # 只看指定行范围
```

| 占位符 | 含义 |
| ------ | ---- |
| `%h` / `%H` | 短 / 完整哈希 |
| `%an` / `%ae` | 作者名 / 邮箱 |
| `%ad` / `%ar` | 作者日期 / 相对时间 |
| `%s` | 提交信息首行 |
| `%d` | 引用（分支、标签） |

## 五、撤销与回退

```bash
git restore <file>                    # 丢弃工作区改动
git restore --staged <file>           # 取消暂存（保留改动）
git restore -s <commit> -- <file>     # 用历史版本覆盖工作区
git reset <commit>                    # 移动 HEAD，保留改动在暂存区（mixed）
git reset --soft <commit>             # 移动 HEAD，改动留在暂存区
git reset --hard <commit>             # 移动 HEAD，丢弃所有改动（危险）
git revert <commit>                   # 生成反向提交
git revert -m 1 <merge-commit>        # 回滚一次合并
git clean -n                          # 预演删除未跟踪文件
git clean -fd                         # 删除未跟踪文件与目录（危险）
```

| 场景 | 推荐命令 | 是否改写历史 |
| ---- | -------- | ------------ |
| 撤销未暂存改动 | `git restore <file>` | 否 |
| 取消暂存 | `git restore --staged <file>` | 否 |
| 修改上一条提交 | `git commit --amend` | 是（仅本地） |
| 撤销已推送提交 | `git revert <commit>` | 否 |
| 丢弃最近 n 次提交 | `git reset --hard HEAD~n` | 是 |
| 找回误删提交 | `git reflog` → `git reset --hard <hash>` | — |

`git reflog` 记录 HEAD 的每次移动，默认保留 90 天，是本地误操作的兜底。

## 六、分支

```bash
git branch                          # 本地分支
git branch -a                       # 含远程分支
git branch -vv                      # 含跟踪关系与最新提交
git branch <name>                   # 创建分支
git branch -m <old> <new>           # 重命名
git branch -d <name>                # 删除已合并分支
git branch -D <name>                # 强制删除
git switch <name>                   # 切换
git switch -c <name>                # 新建并切换
git switch -c <name> origin/<name>  # 基于远程分支新建
git switch -                      # 回到上一个分支
```

合并与变基：

```bash
git merge <branch>                  # 合并到当前分支
git merge --no-ff <branch>          # 保留分支记录
git merge --squash <branch>         # 压成一个提交，不产生合并提交
git merge --abort                   # 放弃本次合并
git rebase <base>                   # 把当前分支提交接到 base 之后
git rebase -i HEAD~5                # 交互式整理最近 5 个提交
git rebase --continue / --abort / --skip
git cherry-pick <commit>            # 摘取单个提交
git cherry-pick <a>..<b>            # 摘取区间
```

交互式 rebase 指令（`pick` 可换成下列之一）：

| 指令 | 作用 |
| ---- | ---- |
| `pick` | 保留该提交 |
| `reword` | 改提交信息 |
| `edit` | 暂停以便修改内容 |
| `squash` | 合并进上一个提交并合并信息 |
| `fixup` | 合并进上一个提交并丢弃信息 |
| `drop` | 删除该提交 |

> [!warning] rebase 会重写提交哈希，只对尚未共享的本地分支使用。

## 七、远程仓库

```bash
git remote -v                              # 查看远程地址
git remote add <name> <url>                # 添加远程
git remote set-url <name> <url>            # 修改地址
git remote rename <old> <new>
git remote remove <name>
git remote show <name>                     # 远程分支与跟踪详情
git fetch <remote>                         # 下载更新，不合并
git fetch --prune                          # 同时清理已删除的远程分支
git pull                                   # fetch + merge
git pull --rebase                          # fetch + rebase，历史更线性
git push -u <remote> <branch>              # 首次推送并建立跟踪
git push                                   # 推送当前分支
git push <remote> --delete <branch>        # 删除远程分支
git push --tags                            # 推送标签
git push --force-with-lease                # 安全的强推
```

| 场景 | 命令 |
| ---- | ---- |
| 推送被拒（non-fast-forward） | `git pull --rebase` 后重新推送 |
| 本地分支跟踪远程 | `git branch -u origin/<branch>` |
| 查看未推送提交 | `git log @{u}..` |
| 查看远程默认分支 | `git remote show origin` |
| 清理失效远程引用 | `git remote prune origin` |

> [!warning] `--force` 会覆盖远程历史，可能丢失他人提交；优先用 `--force-with-lease`。

## 八、暂存（stash）

```bash
git stash                        # 暂存当前改动
git stash push -m "wip: ui"      # 带说明
git stash push -- <path>         # 只暂存指定文件
git stash -u                     # 含未跟踪文件
git stash list                   # 查看列表
git stash show -p stash@{0}      # 查看内容
git stash pop                    # 恢复并删除记录
git stash apply stash@{0}        # 恢复但保留记录
git stash drop stash@{0}         # 删除记录
git stash clear                  # 清空全部
git stash branch <name>          # 从暂存内容新建分支
```

## 九、标签

```bash
git tag                          # 列出标签
git tag -l "v1.*"                # 按模式过滤
git tag v1.0.0                   # 轻量标签
git tag -a v1.0.0 -m "release"   # 附注标签（推荐）
git tag -a v1.0.0 <commit>       # 给历史提交打标签
git show v1.0.0
git push origin v1.0.0           # 推送单个标签
git push origin --tags
git tag -d v1.0.0                # 删除本地标签
git push origin :refs/tags/v1.0.0  # 删除远程标签
```

## 十、搜索与定位

```bash
git grep "TODO"                  # 在工作区搜索已跟踪文件
git grep -n "TODO" -- "*.py"     # 显示行号并限定文件
git log -S "needle"              # 内容增删搜索（pickaxe）
git log -G "regex"               # 按正则匹配差异
git bisect start                 # 二分定位引入 bug 的提交
git bisect bad                   # 标记当前为坏
git bisect good <commit>         # 标记已知好提交
git bisect reset                 # 结束并回到原分支
```

`git bisect run <script>` 可自动化：脚本返回 0 视为 good，1-127 视为 bad。

## 十一、补丁、归档与工作树

```bash
git format-patch -1 <commit>          # 导出为 .patch 邮件格式
git format-patch origin/main          # 导出本分支领先的提交
git am <file.patch>                   # 应用并保留提交信息
git apply <file.patch>                # 只应用改动，不建提交
git apply --check <file.patch>        # 预检能否应用
git archive --format=zip HEAD -o src.zip
git worktree add ../hotfix main       # 另一目录检出分支
git worktree list
git worktree remove ../hotfix
```

## 十二、子模块

```bash
git submodule add <url> <path>
git submodule status
git submodule update --init --recursive
git submodule update --remote         # 跟到远程最新
git clone --recurse-submodules <url>
```

## 十三、维护与排错

```bash
git gc                       # 垃圾回收，压缩对象
git fsck                     # 检查仓库完整性
git count-objects -vH        # 查看对象占用
git prune                    # 清理不可达对象
git repack -ad
git update-index --assume-unchanged <file>   # 临时忽略本地改动
git update-index --no-assume-unchanged <file>
git fsck --lost-found        # 找回丢失的对象
```

| 问题 | 排查命令 |
| ---- | -------- |
| 仓库异常变大 | `git count-objects -vH` → `git gc --aggressive` |
| 提交历史错乱 | `git reflog` |
| 文件被误忽略 | `git check-ignore -v <file>` |
| 合并冲突状态卡住 | `git status` → `git merge --abort` |
| 分支跟踪丢失 | `git branch -vv` → `git branch -u origin/<b>` |

## 十四、钩子（hooks）

钩子放在 `.git/hooks/`，去掉 `.sample` 后缀并赋予可执行权限即生效。常用：

| 钩子 | 触发时机 | 典型用途 |
| ---- | -------- | -------- |
| `pre-commit` | 提交前 | 代码格式、静态检查、单测 |
| `commit-msg` | 提交信息写好但未入库 | 校验提交信息规范 |
| `pre-push` | 推送前 | 跑完整测试 |
| `post-merge` | 合并后 | 更新依赖、生成文件 |

团队协作中可用 `core.hooksPath` 指向版本库内的 `hooks/` 目录，避免每台机器手动配置。

## 十五、常见错误速查

| 报错 / 现象 | 原因 | 处理 |
| ----------- | ---- | ---- |
| `not a git repository` | 不在仓库目录 | `git init` 或 `cd` 到正确目录 |
| `Your local changes would be overwritten` | 有未提交改动 | `git stash` 或先提交 |
| `fatal: refusing to merge unrelated histories` | 两条独立历史 | `git pull --allow-unrelated-histories` |
| `error: pathspec did not match` | 路径或分支名写错 | 检查拼写，注意大小写 |
| `detached HEAD` | 检出了提交而非分支 | `git switch -c <new>` 或 `git switch <branch>` |
| `permission denied (publickey)` | SSH 密钥未配置 | 生成密钥并添加到平台 |
| `index.lock` 已存在 | 上次操作异常中断 | 确认无 Git 进程后删除该文件 |

## 相关笔记

- [[Git]] — 概念速览与最小命令集
- [[Git入门文档]] — 从零开始的完整操作教程
- [[架构与工程]] — 工程化目录导航

## 参考来源

- [Git 官方命令参考](https://git-scm.com/docs)
- [Pro Git 中文版](https://git-scm.com/book/zh/v2)
