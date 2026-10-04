---
date: 2026-10-02
related:
  - "[[../../知识积累/编程/教程/前端/JavaScript入门文档]]"
---
# 类型转换

## string + number 为 string

> [!note]
> JS似乎会将所有与string相加的变量都变成string

```javascript
const text = "hello, world!"

console.log(text);
console.log(typeof text);

const num = text + 1;
//1 + text同样

console.log(num);
console.log(typeof num);
```

输出

```
hello, world!
string
hello, world!1
string
```
