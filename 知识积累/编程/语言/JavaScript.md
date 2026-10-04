---
title: JavaScript
date: 2026-10-02
tags:
  - 前端
  - JavaScript
aliases:
  - JS
  - ECMAScript
related:
  - "[[Node.js]]"
  - "[[JSON]]"
  - "[[API]]"
---

# JavaScript

JavaScript（简称 JS）是一门动态类型、基于原型的脚本语言，最初用于浏览器网页交互，如今通过 [[Node.js]] 也广泛用于后端、桌面端和工具链，是事实上的「全栈」语言。

## 核心要点

- **动态类型 + 弱类型**：变量类型在运行时确定，运算时会自动做隐式转换（也是常见坑的来源）。
- **单线程 + 事件循环**：主线程一次只执行一段代码，靠事件循环和异步回调处理并发 I/O。
- **基于原型**：对象通过原型链继承，`class` 只是原型机制的语法糖。
- **无处不在**：浏览器、[[Node.js]]、Electron、React Native 等运行时都能跑。

## 语言基础

### 变量声明

| 关键字 | 作用域 | 可变 | 说明 |
| ------ | ------ | ---- | ---- |
| `var` | 函数作用域 | 是 | 旧写法，存在变量提升，尽量避免 |
| `let` | 块级作用域 | 是 | 现代默认选择 |
| `const` | 块级作用域 | 否（引用不变） | 优先使用，对象内容仍可修改 |

### 数据类型

- 原始类型：`string`、`number`、`boolean`、`null`、`undefined`、`symbol`、`bigint`
- 引用类型：`object`（含数组、函数、日期等）

```javascript
const user = { name: "Ada", age: 36 };
const nums = [1, 2, 3];
console.log(typeof user); // "object"
console.log(Array.isArray(nums)); // true
```

### 函数与箭头函数

```javascript
function add(a, b) {
  return a + b;
}

const add2 = (a, b) => a + b; // 箭头函数，无自己的 this
```

> [!warning] 待确认：箭头函数的 `this` 指向在对象方法和事件回调中容易混淆，使用时注意上下文。

## 异步编程

JS 用事件循环处理异步任务，演进路线：回调 → Promise → `async/await`。

```javascript
async function fetchUser(id) {
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json(); // 返回 [[JSON]] 数据
}

fetchUser(1).then((user) => console.log(user)).catch(console.error);
```

- **宏任务**：`setTimeout`、I/O、UI 渲染。
- **微任务**：Promise 回调、`queueMicrotask`，优先级高于宏任务。

## 模块化

```javascript
// ES Module（现代标准）
import { readFile } from "node:fs/promises";
export function greet(name) {
  return `Hello, ${name}`;
}
```

- **ESM**：`import` / `export`，浏览器和 [[Node.js]] 均支持。
- **CommonJS**：`require` / `module.exports`，[[Node.js]] 历史写法。

## 常见坑

| 现象 | 原因 | 建议 |
| ---- | ---- | ---- |
| `0.1 + 0.2 !== 0.3` | 浮点数精度 | 用整数或误差比较 |
| `[] == false` 为真 | 隐式类型转换 | 一律用 `===` / `!==` |
| `this` 指向丢失 | 调用方式不同 | 箭头函数或 `bind` |
| 循环里用 `var` | 共享同一变量 | 改用 `let` |

## 相关笔记

- [[Node.js]] — 服务端 JavaScript 运行时
- [[JSON]] — JS 对象表示法，数据交换格式
- [[API]] — 用 JS 调用或提供网络接口
- [[编程]] — 编程知识目录导航

## 参考来源

- [MDN: JavaScript](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript)
- [ECMAScript 规范](https://tc39.es/ecma262/)
