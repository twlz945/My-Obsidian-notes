---
title: HTML 入门文档
date: 2026-10-02
tags:
  - 前端
  - HTML
  - 教程
aliases:
  - HTML入门
  - HyperText Markup Language
related:
  - "[[前端/CSS入门文档]]"
  - "[[JavaScript入门文档]]"
  - "[[前端]]"
---

# HTML 入门文档

HTML（HyperText Markup Language，超文本标记语言）用「标签」描述网页的**结构与内容**：标题、段落、图片、链接、表单等。它是网页的骨架，[[前端/CSS入门文档|CSS]] 负责外观，[[JavaScript入门文档|JavaScript]] 负责交互。

## 核心要点

- **不是编程语言**：没有变量、循环、逻辑，只有标记（markup）。
- **文档即结构树**：浏览器把标签解析成 DOM 树，[[前端/CSS入门文档|CSS]] 和 [[JavaScript入门文档|JavaScript]] 都作用于这棵树。
- **语义化优先**：用含义正确的标签（如 `<nav>`、`<article>`），而不是一堆 `<div>`。
- **解析宽容**：标签写错浏览器也会尽量渲染，但不代表可以随意写。

## 一、最小文档结构

```html
<!DOCTYPE html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>我的第一个页面</title>
  </head>
  <body>
    <h1>Hello, HTML</h1>
    <p>这是第一段文字。</p>
  </body>
</html>
```

| 部分 | 作用 |
| ---- | ---- |
| `<!DOCTYPE html>` | 声明 HTML5，避免浏览器进入怪异模式 |
| `<html lang="zh-CN">` | 根元素，`lang` 有助屏幕阅读器与翻译 |
| `<head>` | 元信息：编码、视口、标题、样式与脚本引用 |
| `<body>` | 用户可见的页面内容 |

## 二、常用标签

### 文本与结构

```html
<h1>一级标题</h1>
<h2>二级标题</h2>
<p>段落文本，<strong>加粗强调</strong>，<em>斜体强调</em>。</p>
<blockquote>引用一段话。</blockquote>
<ul>
  <li>无序列表项</li>
</ul>
<ol>
  <li>有序列表项</li>
</ol>
```

> [!tip] 标题层级按内容重要性使用，不要为了字号去跳级用 `<h1>`，字号交给 [[前端/CSS入门文档|CSS]]。

### 链接与图片

```html
<a href="https://example.com" target="_blank" rel="noopener">外链</a>
<a href="/about">站内链接</a>
<a href="#section-1">页内锚点</a>

<img src="cat.png" alt="一只橘猫趴在键盘上" width="320" />
```

- `alt` 在图片加载失败或屏幕阅读器场景替代图片内容，务必填写。
- `target="_blank"` 建议搭配 `rel="noopener"`，避免安全与性能问题。

### 语义化布局

```html
<header>页头：logo、标题、导航</header>
<nav>导航链接</nav>
<main>
  <article>
    <h2>文章标题</h2>
    <section>文章的一节</section>
  </article>
  <aside>侧边栏</aside>
</main>
<footer>页脚</footer>
```

| 标签 | 语义 |
| ---- | ---- |
| `<header>` | 页头或区块头部 |
| `<nav>` | 主要导航 |
| `<main>` | 页面唯一主体内容（一页只用一个） |
| `<article>` | 可独立分发的内容（文章、卡片） |
| `<section>` | 有主题的分组，通常带标题 |
| `<aside>` | 与主内容相关的补充 |
| `<footer>` | 页脚 |

## 三、属性

属性写在开始标签内，形如 `name="value"`：

| 属性 | 说明 |
| ---- | ---- |
| `id` | 全页唯一标识，供锚点、[[前端/CSS入门文档\|CSS]]、JS 使用 |
| `class` | 可复用类名，多个用空格分隔 |
| `style` | 内联样式，适合临时调试，正式样式应放 CSS |
| `data-*` | 自定义数据，如 `data-id="42"`，JS 可读取 |
| `hidden` | 隐藏元素 |
| `title` | 悬停提示 |

```html
<button class="btn btn-primary" data-id="42" title="点击提交">提交</button>
```

## 四、表单

```html
<form action="/login" method="post">
  <label for="email">邮箱</label>
  <input id="email" name="email" type="email" required placeholder="you@example.com" />

  <label for="pwd">密码</label>
  <input id="pwd" name="password" type="password" minlength="8" required />

  <label>
    <input type="checkbox" name="remember" /> 记住我
  </label>

  <select name="role">
    <option value="user">普通用户</option>
    <option value="admin">管理员</option>
  </select>

  <textarea name="bio" rows="3"></textarea>
  <button type="submit">登录</button>
</form>
```

> [!warning] `label` 的 `for` 必须等于对应控件的 `id`，点击文字才能聚焦输入框（可访问性要求）。

常用 `input type`：`text`、`email`、`password`、`number`、`date`、`file`、`radio`、`checkbox`、`submit`。

## 五、接入 CSS 与 JavaScript

```html
<head>
  <!-- 外部样式：放在 head，避免闪烁 -->
  <link rel="stylesheet" href="/styles/main.css" />
  <!-- defer：等 HTML 解析完再按顺序执行 -->
  <script src="/js/app.js" defer></script>
</head>
```

- 样式优先用外部 `<link>`，便于缓存与复用。
- 脚本建议加 `defer`，避免阻塞解析；需要更早执行可用 `async`（不保证顺序）。

## 六、常见坑

| 现象 | 原因 | 建议 |
| ---- | ---- | ---- |
| 中文乱码 | 缺少 `<meta charset="UTF-8">` | 在 `head` 最前面声明编码 |
| 移动端显示变小 | 缺少 viewport meta | 加 `width=device-width, initial-scale=1.0` |
| 点击文字无法聚焦 | `label` 未绑定 `for`/`id` | 正确关联 |
| 图片读屏无描述 | `alt` 缺失 | 有意义的图写描述，纯装饰写 `alt=""` |
| 出现多个 `<main>` | 误用语义标签 | 一页只保留一个 `<main>` |
| 标签未闭合 | 手写遗漏 | 编辑器装格式化 / 校验插件 |

## 七、学习路线与练习

| 阶段 | 内容 | 练习 |
| ---- | ---- | ---- |
| 入门 | 文档结构、文本 / 链接 / 图片 | 个人简介页 |
| 进阶 | 列表、表格、语义化布局 | 一篇博客文章页 |
| 实战 | 表单、可访问性 | 登录 / 注册表单 |
| 综合 | 结合 [[前端/CSS入门文档\|CSS]] 与 [[JavaScript入门文档\|JavaScript]] | 完整落地页 |

## 相关笔记

- [[HTML]] — 系统参考笔记
- [[前端/CSS入门文档]] — 用样式控制 HTML 的外观
- [[JavaScript入门文档]] — 为页面添加交互
- [[TypeScript入门文档]] — 类型化的 JS
- [[前端]] — 前端知识目录导航
- [[Markdown语法]] — 另一种更轻量的标记语言

## 参考来源

- [MDN: HTML 基础](https://developer.mozilla.org/zh-CN/docs/Learn/Getting_started_with_the_web/HTML_basics)
- [MDN: HTML 元素参考](https://developer.mozilla.org/zh-CN/docs/Web/HTML/Element)
