---
title: CSS
date: 2026-10-02
tags:
  - 前端
  - CSS
aliases:
  - Cascading Style Sheets
  - 层叠样式表
related:
  - "[[HTML]]"
  - "[[JavaScript]]"
  - "[[../教程/前端/CSS入门文档]]"
---

# CSS

CSS（Cascading Style Sheets，层叠样式表）是网页的**表现层**，把样式规则应用到 [[HTML]] 生成的 DOM 树上。它的核心机制是「层叠 + 继承 + 盒模型 + 布局」。本篇为系统参考，入门步骤见 [[../教程/前端/CSS入门文档]]。

## 核心要点

- **层叠（Cascade）**：多规则冲突时，按来源、优先级、顺序裁决。
- **继承（Inheritance）**：字体、颜色等属性会传给子元素，盒模型属性通常不继承。
- **盒模型**：元素是矩形盒，`box-sizing` 决定宽高是否含内边距与边框。
- **格式化上下文**：普通流、Flex、Grid 各有布局规则，理解它能解释多数「诡异」排版。

## 规则结构

```css
/* 选择器 { 属性: 值; } */
.card > .title {
  font-size: 1.25rem;
  color: var(--primary, #2563eb);
}
```

- **样式表来源**：作者样式、用户样式、浏览器默认样式。
- **引入方式**：外部 `<link>`、内部 `<style>`、内联 `style`。

## 选择器体系

| 类别 | 示例 | 说明 |
| ---- | ---- | ---- |
| 类型 | `p` | 元素名 |
| 类 | `.card` | 可复用 |
| ID | `#app` | 唯一 |
| 属性 | `[type="email"]` | 按属性匹配 |
| 伪类 | `:hover` `:focus-visible` `:nth-child()` | 状态 / 位置 |
| 伪元素 | `::before` `::after` `::first-line` | 生成 / 局部 |
| 组合器 | `A B` `A > B` `A + B` `A ~ B` | 后代 / 子 / 相邻 / 通用兄弟 |
| 逻辑 | `:is()` `:where()` `:not()` `:has()` | 组合条件 |

## 优先级与层叠

优先级权重 `(ID, 类 / 属性 / 伪类, 元素 / 伪元素)`：

| 选择器 | 权重 |
| ------ | ---- |
| `p` | (0,0,1) |
| `.card` | (0,1,0) |
| `#app .card` | (1,1,0) |
| 内联 `style` | 高于普通选择器 |

层叠顺序（从低到高）：来源与重要性 → `@layer` 层级 → 优先级 → 书写顺序。`!important` 反向作用于来源顺序，应谨慎使用。

## 盒模型

```css
* { box-sizing: border-box; }
```

| 值 | `width` 含义 |
| -- | ------------ |
| `content-box`（默认） | 仅内容区 |
| `border-box` | 内容 + padding + border |

- **外边距折叠**：相邻块级元素的垂直 `margin` 取较大值。
- **溢出**：`overflow: hidden / auto / visible`。
- **BFC**：`display: flow-root`、`overflow` 非 `visible` 等可创建独立格式化上下文，用于清除浮动、阻止折叠。

## 布局体系

| 体系 | 维度 | 典型用途 |
| ---- | ---- | -------- |
| 普通流 | — | 默认文档流 |
| 浮动 float | — | 旧式排版，现多被 Flex / Grid 取代 |
| Flexbox | 一维 | 导航、行内分布、居中 |
| Grid | 二维 | 页面骨架、卡片网格 |
| 多列 | — | 文本分栏 |

```css
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1rem;
}
```

## 定位

| `position` | 参照 | 场景 |
| ---------- | ---- | ---- |
| `static` | 正常流 | 默认 |
| `relative` | 自身 | 作为包含块 |
| `absolute` | 最近定位祖先 | 浮层、角标 |
| `fixed` | 视口 | 固定栏 |
| `sticky` | 滚动容器 | 吸顶 |

`z-index` 只在建立了层叠上下文的元素之间比较。

## 值、单位与函数

| 单位 | 相对对象 |
| ---- | -------- |
| `px` | 绝对 |
| `%` | 父级 |
| `em` | 当前元素字号 |
| `rem` | 根字号 |
| `vw` / `vh` | 视口 |
| `fr` | 网格分数 |
| `ch` | 字符宽 |

- **颜色**：`#rrggbb`、`rgb()`、`hsl()`、`oklch()`。
- **函数**：`calc()`、`min()`、`max()`、`clamp()`、`var()`。
- **自定义属性**：`--name` 定义，`var(--name, fallback)` 使用，可动态切换主题。

## 响应式

```css
@media (min-width: 768px) { ... }
```

- **移动优先**：先写小屏，再用 `min-width` 增强。
- **媒体查询**：按视口 / 设备特性应用样式。
- **容器查询**：`@container` 按父容器尺寸适配组件。
- **流体排版**：`font-size: clamp(1rem, 2.5vw, 1.5rem)`。

## 工程化

- **预处理器**：Sass / Less 提供嵌套与变量（现代 CSS 已原生支持变量、嵌套）。
- **方法论**：BEM 等命名约定降低样式冲突。
- **`@layer`**：显式管理层叠层级，替代 `!important`。
- **构建**：Vite 等工具负责压缩、前缀与热更新，见 [[前端工程化]]。

## 常见坑

| 现象 | 原因 | 建议 |
| ---- | ---- | ---- |
| 宽度算不对 | content-box | 全局 `border-box` |
| 间距异常 | margin 折叠 | 用 padding 或 `flow-root` |
| 覆盖不掉 | 优先级 / 顺序 | 用 `@layer` 或降低选择器层级 |
| 绝对定位偏移 | 无定位祖先 | 父级 `position: relative` |
| `z-index` 无效 | 未建层叠上下文 | 检查祖先 `transform` / `opacity` 等 |
| 移动端点击延迟 | 历史 300ms | 声明 viewport |

## 相关笔记

- [[../教程/前端/CSS入门文档]] — 面向零基础的分步教程
- [[HTML]] — 结构层
- [[JavaScript]] — 动态修改类名与样式
- [[前端工程化]] — 样式构建与预处理器
- [[Vite]] — 开发时样式热更新
- [[前端]] — 前端知识目录导航

## 参考来源

- [MDN: CSS](https://developer.mozilla.org/zh-CN/docs/Web/CSS)
- [CSS 规范（W3C）](https://www.w3.org/Style/CSS/)
