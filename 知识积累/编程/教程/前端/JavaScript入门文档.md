---
title: JavaScript 入门文档
date: 2026-10-02
tags:
  - 前端
  - JavaScript
  - 教程
aliases:
  - JS入门
related:
  - "[[JavaScript]]"
  - "[[前端/HTML入门文档]]"
  - "[[前端/CSS入门文档]]"
  - "[[TypeScript入门文档]]"
---

# JavaScript 入门文档

JavaScript（JS）是网页的**行为层**：给 [[前端/HTML入门文档|HTML]] 加交互、响应用户操作、请求数据。它也能通过 [[Node.js]] 跑在服务端。本篇面向零基础入门，语法与机制的系统整理见 [[JavaScript]]。

## 核心要点

- **动态类型**：变量不声明类型，运行时才确定。
- **单线程 + 事件循环**：靠异步回调处理耗时操作，不阻塞页面。
- **基于原型**：对象通过原型链继承。
- **反馈即时**：浏览器里直接就能运行，适合作为第一门语言。

## 一、运行方式

### 浏览器控制台

打开开发者工具（F12）→ Console，直接输入：

```javascript
console.log("Hello, JavaScript");
```

### 页面中引入脚本

```html
<script src="/js/app.js" defer></script>
```

### 用 [[Node.js]] 运行

```bash
node app.js
```

## 二、变量与数据类型

```javascript
let count = 1;        // 可变，块级作用域
const name = "Ada";   // 不可重新赋值，优先使用
var old = true;       // 旧写法，尽量避免

console.log(typeof name); // "string"
```

原始类型：`string`、`number`、`boolean`、`null`、`undefined`、`symbol`、`bigint`；其余是对象（含数组、函数）。

```javascript
const nums = [1, 2, 3];
const user = { name: "Ada", age: 36 };
```

> [!warning] `null` 与 `undefined` 不同：前者表示「故意置空」，后者表示「尚未赋值」。

## 三、运算与流程控制

```javascript
// 建议一律用严格相等
1 === 1;        // true
"1" === 1;      // false（类型不同）

if (count > 0) {
  console.log("正数");
} else if (count === 0) {
  console.log("零");
} else {
  console.log("负数");
}

for (let i = 0; i < 3; i++) console.log(i);

for (const n of nums) console.log(n);       // 遍历值
for (const key in user) console.log(key);   // 遍历键
```

## 四、函数

```javascript
function add(a, b) {
  return a + b;
}

const add2 = (a, b) => a + b;          // 箭头函数
const double = (n) => n * 2;

function greet(name = "world") {         // 默认参数
  return `Hello, ${name}!`;              // 模板字符串
}
```

> [!tip] 箭头函数没有自己的 `this`，适合回调和数组方法；对象方法或需要动态 `this` 时用普通函数。

## 五、数组与对象常用方法

```javascript
const nums = [1, 2, 3, 4];

nums.map((n) => n * 2);              // [2, 4, 6, 8]
nums.filter((n) => n % 2 === 0);     // [2, 4]
nums.reduce((sum, n) => sum + n, 0); // 10
nums.includes(3);                    // true

const user = { name: "Ada", age: 36 };
Object.keys(user);                   // ["name", "age"]
const { name, age } = user;          // 解构
const copy = { ...user, age: 37 };   // 展开复制并覆盖
```

## 六、DOM 与事件

DOM（Document Object Model）是浏览器把 [[前端/HTML入门文档|HTML]] 解析成的对象树，JS 通过它读写页面。

```javascript
// 查询
const title = document.querySelector("h1");
const items = document.querySelectorAll(".item");

// 修改内容与样式
title.textContent = "新标题";
title.classList.add("active");
title.style.color = "tomato";

// 创建并插入
const li = document.createElement("li");
li.textContent = "新项目";
document.querySelector("ul")?.append(li);

// 监听事件
document.querySelector("button")?.addEventListener("click", (event) => {
  console.log("被点击", event.target);
});
```

常见事件：`click`、`input`、`submit`、`keydown`、`mouseover`、`DOMContentLoaded`。

## 七、异步编程

JS 是单线程的，耗时操作（网络、定时器）通过事件循环异步执行。

```javascript
// Promise
fetch("/api/users/1")
  .then((res) => res.json())
  .then((user) => console.log(user))
  .catch((err) => console.error(err));

// async / await（更直观）
async function loadUser(id) {
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json(); // 数据常为 [[JSON]] 格式
}

loadUser(1).catch(console.error);
```

- **宏任务**：`setTimeout`、I/O。
- **微任务**：Promise 回调，优先级更高。

## 八、模块化

```javascript
// math.js
export function add(a, b) {
  return a + b;
}

// main.js
import { add } from "./math.js";
```

- **ESM**：`import` / `export`，现代标准，浏览器与 [[Node.js]] 均支持。
- **CommonJS**：`require` / `module.exports`，Node 历史写法。

## 九、常见坑

| 现象 | 原因 | 建议 |
| ---- | ---- | ---- |
| `0.1 + 0.2 !== 0.3` | 浮点精度 | 用整数运算或误差比较 |
| `[] == false` 为真 | 隐式类型转换 | 一律用 `===` / `!==` |
| `this` 指向丢失 | 调用方式不同 | 箭头函数或 `bind` |
| 循环里全打印同一个值 | 用了 `var` | 改用 `let` |
| 异步结果拿不到 | 没等 Promise | `await` 或在 `.then` 里处理 |
| DOM 取到 `null` | 脚本早于元素执行 | 脚本加 `defer` 或用 `DOMContentLoaded` |

## 十、学习路线与练习

| 阶段 | 内容 | 练习 |
| ---- | ---- | ---- |
| 入门 | 变量、类型、函数 | 计算器函数、温度转换 |
| 进阶 | 数组 / 对象方法 | todo 列表的数据操作 |
| 实战 | DOM 与事件 | 待办清单、计数器 |
| 综合 | 异步与模块 | 用 fetch 请求 [[API]] 并渲染列表 |

## 相关笔记

- [[JavaScript]] — 语法与机制的系统参考
- [[TypeScript入门文档]] — 给 JS 加静态类型
- [[前端/HTML入门文档]] / [[前端/CSS入门文档]] — 网页结构与样式
- [[Node.js]] — 服务端 JS 运行时
- [[JSON]] — JS 对象表示法
- [[API]] — 用 fetch 调用后端接口
- [[编程]] — 编程知识目录导航

## 参考来源

- [MDN: JavaScript 学习区](https://developer.mozilla.org/zh-CN/docs/Learn/JavaScript)
- [现代 JavaScript 教程](https://zh.javascript.info/)
