---
title: Jupyter
date: 2026-10-02
tags:
  - Python
  - 数据科学
  - 教程
aliases:
  - Jupyter Notebook
  - JupyterLab
  - IPython Notebook
related:
  - "[[编程]]"
  - "[[教程/python/用 Python 搭建复杂项目]]"
  - "[[教程/python/Python进阶阶段学习规划表]]"
  - "[[FastAPI]]"
  - "[[Flask]]"
  - "[[Node.js]]"
---

# Jupyter

Jupyter 是一个开源的**交互式计算环境**，让你把代码、运行结果、公式、图表和说明文字放在同一个可执行的文档里，边写边跑、即时查看。它最常用于数据分析、机器学习、科学计算和教学演示。

## 核心要点

- **名字来源**：Jupyter = **Ju**lia + **Py**thon + **R**，现已支持几十种语言（通过不同的 Kernel）。
- **文档单元是 Notebook**：后缀 `.ipynb`，本质是 JSON 格式，记录单元格、代码、输出和元数据。
- **核心抽象是 Kernel**：前端负责交互，Kernel 是真正执行代码的后台进程，两者通过消息协议通信。
- **两大主流前端**：经典 **Jupyter Notebook** 与更现代的 **JupyterLab**。
- 与 [[教程/python/用 Python 搭建复杂项目]] 的工程化思路互补：Notebook 适合探索，正式代码仍应沉淀为模块。

## 详细说明

### 架构：前端 + Kernel + 协议

Jupyter 采用前后端分离设计，理解这三层有助于排查问题：

| 层次 | 职责 | 典型组件 |
| ---- | ---- | -------- |
| 前端（Frontend） | 渲染单元格、编辑、展示输出 | JupyterLab、Notebook、VS Code |
| Kernel | 在独立进程中执行代码并回传结果 | `ipykernel`（Python）、IRkernel（R） |
| 协议（Protocol） | 前后端通信，基于 ZeroMQ + WebSocket | `jupyter_client`、`jupyter_server` |

> [!note]
> Kernel 崩溃（例如内存溢出）时前端仍可存活，重启 Kernel 即可，但会丢失内存中的变量。

### 安装与启动

推荐在虚拟环境中隔离安装，避免与系统环境冲突：

```bash
# 方式一：pip
pip install jupyterlab notebook
jupyter lab        # 启动 JupyterLab
# jupyter notebook # 启动经典 Notebook

# 方式二：conda
conda install -c conda-forge jupyterlab
```

启动后浏览器会打开工作目录，默认地址通常是 `http://localhost:8888`。可用 `--port` 指定端口、`--no-browser` 禁止自动打开。

### Notebook 与 JupyterLab 对比

| 维度 | Jupyter Notebook | JupyterLab |
| ---- | ---------------- | ---------- |
| 界面 | 单文档窗口 | 多标签工作台，可并排编辑器/终端 |
| 扩展性 | 较弱 | 强，支持插件与自定义布局 |
| 定位 | 轻量、易上手 | 现代化 IDE 式环境 |
| 现状 | 仍在维护 | 官方主推方向 |

### 单元格与执行模型

Notebook 由两种单元格组成：

- **Code 单元格**：写代码，`Shift + Enter` 运行并移到下一格，`Ctrl + Enter` 运行并停留。
- **Markdown 单元格**：写文档说明，支持标题、列表、表格、公式（LaTeX）。

执行模型是**有状态**的：变量的值取决于你按什么顺序运行过哪些单元格。这是 Notebook 最强大也最容易踩坑的地方。

> [!warning] 常见陷阱：乱序执行
> 手动跳着运行单元格会导致"结果对不上源码"。建议养成习惯：定期 `Restart Kernel and Run All`，确保从干净状态可复现。做完实验尽早用函数/模块固化关键逻辑。

### 常用魔法命令（Magic Commands）

以 `%` 开头的是行魔法，`%%` 开头的是单元格魔法：

```python
%timeit sum(range(100000))   # 多次运行测耗时
%%time                        # 测整格单次耗时
%matplotlib inline            # 图表内嵌显示

# 自动重载被修改的外部模块，省去反复重启 Kernel
%load_ext autoreload
%autoreload 2

!pip list                     # 以 ! 开头可直接执行 shell 命令
```

### 典型工作流

1. **导入与探索**：加载数据（pandas / numpy），查看前几行、统计分布。
2. **可视化**：用 matplotlib / seaborn / plotly 画图，直接内嵌在输出中。
3. **迭代实验**：反复调整单元格，记录尝试过程与结论。
4. **导出交付**：用 `jupyter nbconvert` 导出为 HTML / PDF / Markdown（`--to html`、`--to markdown`），或通过 `papermill` 参数化批量执行。

### 何时用、何时不用

- ✅ **适合**：数据探索、算法原型、图表呈现、教学讲义、可复现实验报告。
- ⚠️ **不适合**：大型生产服务、需要严格测试与版本控制的复杂应用。这些场景应回归 [[教程/python/用 Python 搭建复杂项目]] 的工程化实践；Notebook 负责"想清楚"，正式代码负责"跑得稳"。
- 若已有 [[FastAPI]] 或 [[Flask]] 后端，Notebook 常作为配套的数据分析/调试入口，而不是替代品。

### 团队协作

- 多人共享时可用 **JupyterHub** 统一管理用户与算力。
- `.ipynb` 是 JSON，直接看 diff 很痛苦；建议配合 `nbdime` 做 Notebook 差异对比，并清除输出后再提交版本控制。

## 相关笔记

- [[编程]] — 编程知识总导航
- [[教程/python/用 Python 搭建复杂项目]] — 工程化项目结构与分层
- [[教程/python/Python进阶阶段学习规划表]] — Python 学习路径
- [[FastAPI]]、[[Flask]] — Python Web 框架，常与 Notebook 配合
- [[Node.js]] — 与之对比的服务端运行时路线

## 参考来源

- [Project Jupyter 官网](https://jupyter.org/)
- [JupyterLab 文档](https://jupyterlab.readthedocs.io/)
- [Jupyter Notebook 文档](https://jupyter-notebook.readthedocs.io/)
