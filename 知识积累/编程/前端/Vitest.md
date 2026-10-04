---
title: Vitest
date: 2026-10-02
tags:
  - 前端
  - 测试
aliases:
  - Vitest
related:
  - "[[单元测试]]"
  - "[[Vite]]"
  - "[[TypeScript]]"
---

# Vitest

Vitest 是面向 Vite 项目的单元测试框架，配置与 [[Vite]] 共用，开箱支持 [[TypeScript]]、ESM 和组件测试。API 与 Jest 高度兼容，迁移成本低，适合数值密集的模拟核心做快速回归。

## 核心要点

- **复用 Vite 配置**：别名、TS、ESM 直接生效，无需额外转译。
- **快**：基于 Vite 的按需转换与智能监听，只重跑受影响的测试。
- **兼容 Jest**：`describe` / `it` / `expect` 写法基本一致。
- **内置覆盖率**：基于 v8 或 istanbul。

## 快速开始

```bash
npm install -D vitest
```

```jsonc
// package.json
{
  "scripts": {
    "test": "vitest",
    "test:run": "vitest run",
    "coverage": "vitest run --coverage"
  }
}
```

## 编写测试

```typescript
import { describe, it, expect } from "vitest";
import { addResource } from "./sim/resources";

describe("资源累加", () => {
  it("应按产量增加库存", () => {
    const state = { iron: 0 };
    addResource(state, "iron", 5);
    expect(state.iron).toBe(5);
  });
});
```

常用能力：

| 能力 | 用法 |
| ---- | ---- |
| 断言 | `expect(x).toBe/toEqual/toThrow` |
| 模拟 | `vi.fn()`、`vi.spyOn()`、`vi.mock()` |
| 定时器 | `vi.useFakeTimers()` |
| 快照 | `toMatchSnapshot()` |
| 覆盖率 | `--coverage` |

## 测试原则

- 一个测试只验证一件事，命名描述「输入 → 期望」。
- 优先测**纯函数**（模拟核心），避免把 DOM、时间、随机数直接写进断言。
- 数值项目重点覆盖边界：0、负数、极大数（见 [[大数（BigNum）]]）、离线跨段结算。

## 相关笔记

- [[单元测试]] — 测试的基本概念与金字塔
- [[Vite]] — Vitest 的运行基础
- [[TypeScript]] — 类型可减少测试中的低级错误
- [[学习规划|游戏开发学习规划]] — 阶段 1 的里程碑验收

## 参考来源

- [Vitest 官方文档](https://vitest.dev/)
