---
title: HTML
date: 2026-10-02
tags:
  - 前端
  - HTML
aliases:
  - HyperText Markup Language
  - 超文本标记语言
related:
  - "[[CSS]]"
  - "[[JavaScript]]"
  - "[[../教程/前端/HTML入门文档]]"
---

# HTML

HTML（HyperText Markup Language，超文本标记语言）是网页的**结构层**，用标签描述内容及其语义。浏览器将其解析为 DOM 树，[[CSS]] 负责表现、[[JavaScript]] 负责行为，三者构成 Web 的「结构 / 表现 / 行为」分离。本篇为系统参考，入门步骤见 [[../教程/前端/HTML入门文档]]。

## 核心要点

- **标记语言**：描述结构而非逻辑，没有控制流。
- **DOM 是运行时模型**：HTML 文本经解析后成为可被脚本操作的对象树。
- **语义与可访问性**：正确的标签既利于搜索引擎，也利于屏幕阅读器。
- **解析宽容**：错误会被纠正，但结构仍有规范可循。

## 文档结构

```html
<!DOCTYPE html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>页面标题</title>
  </head>
  <body>...</body>
</html>
```

`<head>` 放元数据（编码、视口、标题、描述、样式与脚本引用），`<body>` 放可见内容。

## 元素分类

| 类别 | 代表标签 | 说明 |
| ---- | -------- | ---- |
| 文档元数据 | `html` `head` `meta` `title` `link` `script` `style` | 描述文档本身 |
| 分区内容 | `body` `header` `nav` `main` `article` `section` `aside` `footer` | 页面骨架 |
| 文本内容 | `h1`–`h6` `p` `ul` `ol` `li` `dl` `blockquote` `pre` `code` | 组织文字 |
| 行内语义 | `a` `strong` `em` `span` `mark` `time` `abbr` | 行内强调与补充 |
| 图片与多媒体 | `img` `picture` `video` `audio` `canvas` `svg` | 嵌入资源 |
| 表格 | `table` `thead` `tbody` `tr` `th` `td` | 表格式数据 |
| 表单 | `form` `input` `label` `select` `textarea` `button` | 收集输入 |
| 交互 | `details` `summary` `dialog` | 原生交互组件 |

## 全局属性

所有元素通用的属性，常用：

| 属性 | 作用 |
| ---- | ---- |
| `id` | 文档内唯一标识 |
| `class` | 可复用类名，空格分隔多个 |
| `style` | 内联样式（优先用 [[CSS]]） |
| `data-*` | 自定义数据，供 JS 读取 |
| `hidden` | 隐藏 |
| `title` | 悬停提示 |
| `lang` | 内容语言 |
| `tabindex` | 键盘焦点顺序 |
| `contenteditable` | 允许编辑 |

## 语义化与可访问性

- **按含义选标签**：导航用 `<nav>`、独立内容用 `<article>`、主体用 `<main>`，而非清一色 `<div>`。
- **图片提供 `alt`**：信息图写描述，纯装饰用 `alt=""`。
- **表单关联 `label`**：`for` 对应控件 `id`。
- **保持标题层级**：`h1` → `h2` 递进，不跳级。
- **键盘可达**：交互元素优先用原生控件（`button`、`a`），必要时补 ARIA 角色。

## HTML 与 CSS、JavaScript

```html
<link rel="stylesheet" href="/styles/main.css" />
<script src="/app.js" defer></script>
```

| 层 | 技术 | 职责 |
| -- | ---- | ---- |
| 结构 | HTML | 内容与语义 |
| 表现 | [[CSS]] | 布局、颜色、排版 |
| 行为 | [[JavaScript]] | 交互与动态更新 |

## 版本与标准

HTML 由 WHATWG 维护为持续演进的 **Living Standard**；「HTML5」通常指引入语义标签、原生多媒体与表单增强的这一代能力。日常写作以现行标准为准，无需关心版本号。

## 常见实践

| 场景 | 建议 |
| ---- | ---- |
| 编码 | `<meta charset="UTF-8">` 置于 `head` 最前 |
| 移动端 | 声明 viewport meta |
| 图片 | 设 `width` / `height` 减少布局抖动，或配合 `max-width: 100%` |
| 脚本 | 加 `defer` / `async`，避免阻塞解析 |
| 外链新窗口 | `target="_blank"` 搭配 `rel="noopener"` |
| 结构 | 用语义标签，减少无语义 `<div>` 嵌套 |

## 相关笔记

- [[../教程/前端/HTML入门文档]] — 面向零基础的分步教程
- [[CSS]] — 表现层
- [[JavaScript]] — 行为层，操作 DOM
- [[前端]] — 前端知识目录导航
- [[Markdown语法]] — 另一种轻量标记语言

## 参考来源

- [MDN: HTML](https://developer.mozilla.org/zh-CN/docs/Web/HTML)
- [HTML Living Standard](https://html.spec.whatwg.org/)
