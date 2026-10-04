---
title: TypeScript
date: 2026-10-02
tags:
  - 前端
  - TypeScript
aliases:
  - TS
related:
  - "[[JavaScript]]"
  - "[[Node.js]]"
  - "[[前端工程化]]"
---

# TypeScript

TypeScript（简称 TS）是 [[JavaScript]] 的超集：在 JS 语法之上增加**静态类型系统**，编译后仍是标准 JS。它把「运行时才发现的类型错误」提前到编码和编译阶段，是大型前端/Node 项目的主流选择。

## 核心要点

- **超集而非新语言**：任何合法 JS 都是合法 TS，可渐进式迁移。
- **类型只在编译期存在**：类型标注会被擦除，不产生运行时开销。
- **结构类型**：类型兼容看「形状」而非名义继承，与 Python 的类型提示思路相近。
- **强工具支持**：编辑器自动补全、跳转、重命名重构都依赖类型信息。

## 基础类型与语法

```typescript
let count: number = 1;
let name: string = "Ada";
let done: boolean = false;
let ids: number[] = [1, 2, 3];
let pair: [string, number] = ["age", 36]; // 元组

// 对象接口
interface User {
  id: number;
  name: string;
  age?: number; // 可选属性
  readonly createdAt: Date;
}

// 类型别名 + 联合类型
type Status = "idle" | "running" | "done";
```

### interface 与 type

| 维度 | `interface` | `type` |
| ---- | ----------- | ------ |
| 声明合并 | 支持（可多次声明同名） | 不支持 |
| 联合/交叉 | 需借助 type | 直接支持 |
| 适用 | 对象、类的契约 | 任意类型别名、函数类型 |

## 泛型与类型收窄

```typescript
function first<T>(arr: T[]): T | undefined {
  return arr[0];
}

function printId(id: string | number) {
  if (typeof id === "string") {
    console.log(id.toUpperCase()); // 此处收窄为 string
  } else {
    console.log(id.toFixed(0)); // number
  }
}
```

常用工具类型：`Partial<T>`、`Required<T>`、`Pick<T, K>`、`Omit<T, K>`、`Record<K, V>`、`ReturnType<F>`。

## 编译与配置

```bash
npm install -D typescript
npx tsc --init          # 生成 tsconfig.json
npx tsc                 # 编译
npx tsc --noEmit        # 只做类型检查
```

`tsconfig.json` 关键项：

```jsonc
{
  "compilerOptions": {
    "strict": true,          // 打开全部严格检查，建议必开
    "target": "ES2022",      // 输出目标
    "module": "ESNext",
    "moduleResolution": "bundler",
    "noUncheckedIndexedAccess": true,
    "skipLibCheck": true
  }
}
```

## 与 JavaScript 的差异

| 维度 | JavaScript | TypeScript |
| ---- | ---------- | ---------- |
| 类型检查 | 运行时动态 | 编译期静态 |
| 报错时机 | 运行后 | 编码/编译时 |
| 运行方式 | 直接执行 | 先编译或由 Vite/tsx 转译 |
| 适用规模 | 小脚本、快速原型 | 中大型项目、多人协作 |

## 实践建议

- **开启 `strict`**，不要用 `any` 逃避类型；不确定时先用 `unknown` 再收窄。
- **类型即文档**：公共函数、模块边界写清签名，内部可依赖推断。
- **数据边界校验**：类型无法校验运行时输入（如接口返回），可配合 Zod 等库。
- 游戏开发路线 A 的技术栈即 TypeScript + [[前端工程化|Vite]]，可参考 [[学习规划|游戏开发学习规划]]。

## 相关笔记

- [[JavaScript]] — TypeScript 的语言基础
- [[Node.js]] — 服务端运行与类型支持
- [[npm]] — 安装与管理 TypeScript 依赖
- [[前端工程化]] — 编译、打包与工具链
- [[编程]] — 编程知识目录导航

## 参考来源

- [TypeScript 官方文档](https://www.typescriptlang.org/docs/)
- [TypeScript Handbook（中文）](https://www.typescriptlang.org/zh/docs/handbook/intro.html)
