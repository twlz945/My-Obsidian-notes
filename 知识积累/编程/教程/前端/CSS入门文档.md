---
title: CSS 入门文档
date: 2026-10-02
tags:
  - 前端
  - CSS
  - 教程
aliases:
  - CSS入门
  - Cascading Style Sheets
  - 层叠样式表
related:
  - "[[HTML入门文档]]"
  - "[[JavaScript入门文档]]"
  - "[[前端]]"
---

# CSS 入门文档

CSS（Cascading Style Sheets，层叠样式表）负责网页的**外观与排版**：颜色、字体、间距、布局、动画。它作用在 [[HTML入门文档|HTML]] 生成的 DOM 树上，与 HTML（结构）、[[JavaScript入门文档|JavaScript]]（行为）共同构成网页三要素。

## 核心要点

- **层叠（Cascade）**：多个规则同时命中一个元素时，按来源、优先级、书写顺序决定谁生效。
- **选择器驱动**：用选择器定位元素，再声明属性值。
- **盒模型**：每个元素都是一个矩形盒子（内容 + 内边距 + 边框 + 外边距）。
- **默认 `box-sizing: content-box`**：设置 `border-box` 后宽高包含内边距和边框，计算更直观。

## 一、引入方式

```html
<!-- 外部样式（推荐） -->
<link rel="stylesheet" href="/styles/main.css" />

<style>
  /* 内部样式，适合单页或演示 */
  body { margin: 0; }
</style>

<p style="color: red">内联样式，优先级高但不便维护</p>
```

优先级（从低到高）：外部 / 内部样式 → 内联样式 → `!important`。日常优先外部样式表。

## 二、选择器

```css
p { color: #333; }                 /* 元素 */
.card { padding: 16px; }           /* 类 */
#app { max-width: 960px; }         /* ID */
input[type="email"] { border: 1px solid; } /* 属性 */
a:hover { text-decoration: underline; }     /* 伪类 */
p::first-line { font-weight: bold; }        /* 伪元素 */

/* 组合器 */
nav a { color: inherit; }          /* 后代 */
ul > li { list-style: square; }    /* 直接子元素 */
h2 + p { margin-top: 0; }          /* 紧邻兄弟 */
```

### 优先级（specificity）

大致权重：内联样式 > ID > 类 / 属性 / 伪类 > 元素 / 伪元素。计算形如 `(ID 数, 类数, 元素数)`：

| 选择器 | 权重 |
| ------ | ---- |
| `p` | (0,0,1) |
| `.card` | (0,1,0) |
| `#app .card` | (1,1,0) |
| `style="..."` | 高于所有选择器 |

> [!tip] 与其堆 `!important`，不如减少选择器层级、用类名组织样式。

## 三、盒模型

```css
* { box-sizing: border-box; }

.box {
  width: 200px;              /* border-box 下含 padding 与 border */
  padding: 16px;
  border: 2px solid #ccc;
  margin: 12px;
}
```

| 组成 | 说明 |
| ---- | ---- |
| content | 内容区 |
| padding | 内边距，撑开背景 |
| border | 边框 |
| margin | 外边距，元素之间的距离 |

相邻元素的垂直 `margin` 会**折叠**（取较大值），这是常见意外间距的来源。

## 四、布局

### 普通流（Normal Flow）

块级元素自上而下排列，行内元素自左而右排列。改布局时常先用 `<div>` 分组，再用 Flex / Grid 排布。

### Flexbox（一维）

```css
.row {
  display: flex;
  justify-content: space-between; /* 主轴对齐 */
  align-items: center;            /* 交叉轴对齐 */
  gap: 12px;
}
.row .item { flex: 1 1 0; }       /* 等宽伸缩 */
```

适合导航栏、卡片行、居中等。

### Grid（二维）

```css
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}
```

`auto-fit` + `minmax` 可自动换行，是响应式卡片网格的常用写法。

## 五、定位

```css
.parent { position: relative; }
.badge {
  position: absolute;
  top: 0;
  right: 0;
}
.fixed-nav {
  position: fixed;
  top: 0;
  width: 100%;
}
.sticky-head {
  position: sticky;
  top: 0;
}
```

| 值 | 参照物 | 场景 |
| -- | ------ | ---- |
| `static` | 默认，正常流 | — |
| `relative` | 自身原位置 | 作为 absolute 的定位祖先 |
| `absolute` | 最近的已定位祖先 | 角标、弹层 |
| `fixed` | 视口 | 固定导航 |
| `sticky` | 滚动容器 | 吸顶表头 |

## 六、单位、颜色与变量

| 单位 | 说明 |
| ---- | ---- |
| `px` | 绝对像素 |
| `%` | 相对父级 |
| `rem` | 相对根元素字号，适合整体缩放 |
| `em` | 相对当前元素字号 |
| `vw` / `vh` | 相对视口宽高 |
| `fr` | Grid / Flex 中的比例份额 |

```css
:root {
  --primary: #2563eb;
  --space: 16px;
}
.button {
  color: var(--primary);
  padding: var(--space);
}
```

颜色可用 `#rgb`、`#rrggbb`、`rgb()`、`hsl()`、`oklch()` 等。

## 七、响应式

移动优先：先写小屏样式，再用 `min-width` 媒体查询增强。

```css
.card { width: 100%; }

@media (min-width: 768px) {
  .card { width: 50%; }
}
@media (min-width: 1200px) {
  .card { width: 33.33%; }
}
```

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
```

## 八、常见坑

| 现象 | 原因 | 建议 |
| ---- | ---- | ---- |
| 宽度算不对 | 默认 content-box | 全局 `box-sizing: border-box` |
| 垂直间距比预期大 | margin 折叠 | 用 padding 或父级 `display: flow-root` |
| 绝对定位跑到别处 | 祖先没有定位 | 给父级加 `position: relative` |
| 样式被覆盖 | 优先级 / 顺序 | 开发者工具查看命中的规则 |
| `!important` 越来越多 | 优先级失控 | 降低层级、规范类名 |
| 图片撑破容器 | 未限制宽度 | `img { max-width: 100%; height: auto; }` |

## 九、学习路线与练习

| 阶段 | 内容 | 练习 |
| ---- | ---- | ---- |
| 入门 | 选择器、颜色、字体 | 美化 [[HTML入门文档\|HTML]] 个人简介页 |
| 进阶 | 盒模型、Flex | 导航栏、卡片列表居中 |
| 实战 | Grid、响应式 | 自适应图片画廊 |
| 综合 | 变量、动画、定位 | 个人主页 + 深色主题切换 |

## 相关笔记

- [[CSS]] — 系统参考笔记
- [[HTML入门文档]] — CSS 作用的文档结构
- [[JavaScript入门文档]] — 动态增删样式与类
- [[前端工程化]] — 样式预处理器与构建工具
- [[Vite]] — 开发时热更新 CSS
- [[前端]] — 前端知识目录导航

## 参考来源

- [MDN: CSS 学习区](https://developer.mozilla.org/zh-CN/docs/Learn/CSS)
- [MDN: CSS 参考](https://developer.mozilla.org/zh-CN/docs/Web/CSS)
