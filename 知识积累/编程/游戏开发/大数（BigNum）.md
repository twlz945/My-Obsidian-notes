---
title: 大数（BigNum）
date: 2026-10-02
tags:
  - 游戏开发
  - 编程
aliases:
  - BigNum
  - 大数
related:
  - "[[固定步长循环]]"
  - "[[放置游戏数值设计]]"
  - "[[JSON]]"
---

# 大数（BigNum）

放置游戏里资源会从个位增长到 `1e30`、`1e100` 甚至更大，普通 `number`（双精度浮点）会溢出为 `Infinity` 或丢失精度。大数（BigNum）用**尾数 + 指数**的表示法解决这个问题，是 `学习规划` 阶段 1 的核心数据结构。

## 为什么不用普通数字

- 双精度浮点最大约 `1.8e308`，超过即 `Infinity`。
- 大数相加时，小量会被大量「吞掉」，进度停滞。
- 需要显示为 `1.23e120`、`1.23 万`、`1.23 aa` 等游戏化格式。

## 表示法

把数值写成：

```
value = mantissa × 10^exponent,  1 ≤ |mantissa| < 10
```

```typescript
class BigNum {
  constructor(public mantissa = 0, public exponent = 0) {
    this.normalize();
  }

  private normalize() {
    if (this.mantissa === 0) { this.exponent = 0; return; }
    while (Math.abs(this.mantissa) >= 10) { this.mantissa /= 10; this.exponent++; }
    while (Math.abs(this.mantissa) < 1) { this.mantissa *= 10; this.exponent--; }
  }
}
```

## 基本运算

| 运算 | 规则 |
| ---- | ---- |
| 加/减 | 先对齐指数，再加减尾数（差太大时忽略小项） |
| 乘 | 尾数相乘、指数相加 |
| 除 | 尾数相除、指数相减 |
| 幂 | `mantissa^n`、`exponent × n`（对数思路） |
| 比较 | 先比指数，再比尾数 |

```typescript
add(other: BigNum): BigNum {
  const [a, b] = this.align(other);       // 对齐指数
  return new BigNum(a.mantissa + b.mantissa, a.exponent);
}
```

## 常见坑

- **精度丢失**：`1e20 + 1` 仍等于 `1e20`，小增量无意义；需要「有效增量」时才计入。
- **对齐开销**：指数差极大时不要真的放大，直接按大者返回。
- **序列化**：存档里存 `{ mantissa, exponent }` 而非字符串，见 [[存档序列化与版本迁移]]。
- **显示格式化**：按数量级切换单位（万、亿、aa、ab…），不要直接 `toString`。
- **NaN / Infinity**：运算前防御，避免污染整个存档。

## 相关笔记

- [[固定步长循环]] — 每 tick 累加产出
- [[放置游戏数值设计]] — 增长曲线与单位命名
- [[JSON]] — 存档序列化格式
- [[学习规划|游戏开发学习规划]] — 阶段 1 里程碑

## 参考来源

- [The Math of Idle Games（GDC）](https://www.gdcvault.com/play/1024241/The-Math-of-Idle-Games)
