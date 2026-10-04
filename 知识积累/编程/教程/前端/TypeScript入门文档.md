---
title: TypeScript 入门文档
date: 2026-10-02
tags:
  - 前端
  - TypeScript
  - 教程
aliases:
  - TS入门
related:
  - "[[TypeScript]]"
  - "[[前端/JavaScript入门文档]]"
  - "[[前端工程化]]"
  - "[[Vite]]"
---

# TypeScript 入门文档

TypeScript（TS）是 [[JavaScript]] 的**静态类型超集**：JS 代码在 TS 里都能跑，额外提供类型标注与编译期检查。它把类型错误从「运行后」提前到「写代码时」。类型系统的系统整理见 [[TypeScript]]，本篇面向零基础入门。

## 核心要点

- **超集**：合法 JS 即合法 TS，可渐进迁移。
- **类型在编译期擦除**：运行的是普通 JS，无运行时开销。
- **结构类型**：类型兼容看「形状」，不看名字。
- **工具加成**：补全、跳转、重构、内联报错都依赖类型信息。

## 一、安装与环境

```bash
npm install -D typescript     # 安装到开发依赖
npx tsc --init                # 生成 tsconfig.json
npx tsc                       # 编译成 JS
npx tsc --noEmit              # 只检查类型，不产出文件
```

不想手动编译，可用 `tsx` 直接运行：

```bash
npx tsx app.ts
```

或直接用 [[Vite]] 模板创建带 TS 的前端项目。

## 二、基础类型

```typescript
let count: number = 1;
let name: string = "Ada";
let done: boolean = false;
let nothing: null = null;
let notSet: undefined = undefined;

let ids: number[] = [1, 2, 3];
let pair: [string, number] = ["age", 36]; // 元组

let anything: any = 1;          // 关闭检查，尽量别用
let safe: unknown = getInput(); // 安全，需要收窄后使用

function log(msg: string): void {
  console.log(msg);
}
```

## 三、接口与类型别名

```typescript
interface User {
  id: number;
  name: string;
  age?: number;            // 可选
  readonly createdAt: Date; // 只读
}

type Status = "idle" | "running" | "done"; // 字面量联合

const u: User = { id: 1, name: "Ada", createdAt: new Date() };
```

| 维度 | `interface` | `type` |
| ---- | ----------- | ------ |
| 声明合并 | 支持 | 不支持 |
| 联合 / 交叉 | 需借助 type | 直接支持 |
| 常见用途 | 对象、类的契约 | 任意类型别名 |

## 四、函数与泛型

```typescript
function add(a: number, b: number): number {
  return a + b;
}

// 泛型：让类型随输入变化
function first<T>(arr: T[]): T | undefined {
  return arr[0];
}
const n = first([1, 2, 3]);       // number | undefined
const s = first(["a", "b"]);      // string | undefined

// 泛型约束
function longest<T extends { length: number }>(a: T, b: T): T {
  return a.length >= b.length ? a : b;
}
```

## 五、类型收窄与联合类型

```typescript
type Id = string | number;

function printId(id: Id) {
  if (typeof id === "string") {
    console.log(id.toUpperCase()); // 此处收窄为 string
  } else {
    console.log(id.toFixed(0));    // number
  }
}

// 可辨识联合
interface Ok { status: "ok"; data: string }
interface Err { status: "error"; message: string }
type Result = Ok | Err;

function render(r: Result) {
  if (r.status === "ok") return r.data;
  return r.message; // 收窄为 Err
}
```

## 六、常用工具类型

| 工具类型 | 作用 |
| -------- | ---- |
| `Partial<T>` | 所有属性变可选 |
| `Required<T>` | 所有属性变必填 |
| `Readonly<T>` | 所有属性只读 |
| `Pick<T, K>` | 挑选部分属性 |
| `Omit<T, K>` | 排除部分属性 |
| `Record<K, V>` | 构造键值映射 |
| `ReturnType<F>` | 取函数返回值类型 |

```typescript
type UserUpdate = Partial<Pick<User, "name" | "age">>;
type UserMap = Record<number, User>;
```

## 七、tsconfig 与严格模式

```jsonc
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "noUncheckedIndexedAccess": true,
    "skipLibCheck": true
  }
}
```

> [!tip] 新项目务必开 `strict`；实在不确定类型时先用 `unknown`，收窄后再用。

## 八、常见坑

| 现象 | 原因 | 建议 |
| ---- | ---- | ---- |
| 到处都是 `any` | 图省事 | 用 `unknown` + 收窄或精确类型 |
| 运行时仍崩溃 | 类型不校验外部数据 | 接口数据用 Zod 等库校验 |
| 编译报错看不懂 | 类型推导复杂 | 鼠标悬停在变量上看推断结果 |
| 改一处类型到处报错 | 类型太宽 / 太紧 | 从数据模型出发重构类型 |
| `tsc` 编译慢 | 未开增量 | 开启 `incremental`，或用 [[Vite]] |

## 九、学习路线与练习

| 阶段 | 内容 | 练习 |
| ---- | ---- | ---- |
| 入门 | 基础类型、接口 | 给 [[前端/JavaScript入门文档\|JS]] 练习加类型 |
| 进阶 | 函数、泛型 | 封装类型安全的数组工具 |
| 实战 | 收窄、工具类型 | 建模 [[API]] 返回的 [[JSON]] |
| 综合 | tsconfig、Vite | 用 Vite + TS 建一个小应用 |

## 相关笔记

- [[TypeScript]] — 类型系统的系统参考
- [[前端/JavaScript入门文档]] — TS 的语言基础
- [[前端工程化]] — 编译与打包
- [[Vite]] — 开箱即用的 TS 开发环境
- [[npm]] — 安装 TypeScript 依赖
- [[编程]] — 编程知识目录导航

## 参考来源

- [TypeScript 官方文档](https://www.typescriptlang.org/docs/)
- [TypeScript Handbook（中文）](https://www.typescriptlang.org/zh/docs/handbook/intro.html)
