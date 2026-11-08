---
title: Python 列表
date: 2026-11-01
tags:
  - Python
  - 列表
  - 教程
aliases:
  - Python list
  - Python 列表操作
  - list
related:
  - "[[python/Python 字典]]"
  - "[[python/Python 字符串]]"
  - "[[python/Python进阶阶段学习规划表]]"
---

# Python 列表

Python 的列表类型是 `list`，一种**可变、有序、可重复**的序列，底层是动态数组。它按下标 O(1) 访问，尾部追加摊还 O(1)，是日常开发中使用频率最高的容器之一。

列表可以存放任意类型，也可以嵌套；代价是插入/删除中间元素需要移动后续元素，复杂度为 O(n)。

## 核心要点

- **可变**：可以原地增删改；切片会创建新列表（浅拷贝）。
- **有序**：保持元素插入顺序，支持下标、切片和 `reversed()`。
- **可重复、类型混合**：`[1, "a", 1, None]` 合法。
- `sort()` **原地排序并返回 `None`**；需要新列表用 `sorted()`。
- `append()` 追加一个元素，`extend()` 追加多个元素，二者不要混淆。
- 赋值 `b = a` 只是别名；复制用 `a.copy()`、`list(a)` 或 `a[:]`（都是浅拷贝）。
- `[[0] * 3] * 3` 会让三行共享同一个列表，应改用推导式。
- `x in a` 是 O(n) 线性查找；频繁成员判断考虑 `set`。
- 列表不可哈希，不能作 `dict` 的 key 或放进 `set`。

## 创建列表

```python
a1 = []
a2 = list()
a3 = [1, 2, 3]
a4 = list(range(5))          # [0, 1, 2, 3, 4]
a5 = list("abc")             # ['a', 'b', 'c']
a6 = [x * 2 for x in range(3)]   # [0, 2, 4]
a7 = [0] * 5                 # [0, 0, 0, 0, 0]
```

二维列表要用推导式创建，避免共享引用：

```python
# 错误：三行指向同一个列表
bad = [[0] * 3] * 3
bad[0][0] = 1
print(bad)      # [[1, 0, 0], [1, 0, 0], [1, 0, 0]]

# 正确：每行独立
good = [[0] * 3 for _ in range(3)]
good[0][0] = 1
print(good)     # [[1, 0, 0], [0, 0, 0], [0, 0, 0]]
```

## 索引与切片

```python
a = [10, 20, 30, 40, 50]

a[0]        # 10
a[-1]       # 50
a[1:4]      # [20, 30, 40]     左闭右开
a[:3]       # [10, 20, 30]
a[3:]       # [40, 50]
a[::2]      # [10, 30, 50]
a[::-1]     # [50, 40, 30, 20, 10]
a[100:]     # []               切片越界不报错
# a[100]    # IndexError
```

切片返回**新列表**：

```python
b = a[:]
b[0] = 999
print(a[0])   # 10，原列表不受影响
```

切片赋值可以改变长度：

```python
a = [1, 2, 3, 4]
a[1:3] = [20, 30, 40]
print(a)      # [1, 20, 30, 40, 4]

del a[1:3]
print(a)      # [1, 40, 4]
```

带步长的切片赋值要求长度一致：

```python
a = [0, 0, 0, 0]
a[::2] = [1, 2]     # 正确
# a[::2] = [1]      # ValueError
```

## 增删改

### 添加

```python
a = [1, 2]

a.append(3)          # [1, 2, 3]        追加一个元素
a.extend([4, 5])     # [1, 2, 3, 4, 5] 追加多个元素
a.insert(0, 0)       # [0, 1, 2, 3, 4, 5]
a += [6, 7]          # [0, 1, ..., 7]  原地扩展
```

`append` 与 `extend` 的区别：

```python
a = [1, 2]
a.append([3, 4])     # [1, 2, [3, 4]]
a = [1, 2]
a.extend([3, 4])     # [1, 2, 3, 4]
```

### 删除

```python
a = [10, 20, 30, 20]

a.remove(20)         # 删除第一个 20 → [10, 30, 20]
# a.remove(99)       # ValueError

a.pop()              # 弹出最后一个 → 20
a.pop(0)             # 弹出指定下标 → 10

del a[0]             # 按下标删除
del a[1:3]           # 删除切片
a.clear()            # 清空
```

### 修改

```python
a = [1, 2, 3]
a[0] = 100           # [100, 2, 3]
a[1:3] = [20, 30]    # [100, 20, 30]
```

## 查找与统计

```python
a = [10, 20, 30, 20]

a.index(20)          # 1，首次出现的下标
# a.index(99)        # ValueError
a.index(20, 2)       # 3，从下标 2 开始找

a.count(20)          # 2
20 in a              # True
99 not in a          # True
```

`index()` 找不到会抛 `ValueError`，不确定时先用 `in` 判断。

## 排序与反转

### `sort()`：原地排序

```python
a = [3, 1, 2]
result = a.sort()
print(a)             # [1, 2, 3]
print(result)        # None   注意：不是排序后的列表
```

### `sorted()`：返回新列表

```python
a = [3, 1, 2]
b = sorted(a)
print(a)             # [3, 1, 2]
print(b)             # [1, 2, 3]
```

### `key` 与 `reverse`

```python
words = ["Apple", "banana", "Cherry"]
sorted(words)                          # 大写字母排在前
sorted(words, key=str.lower)           # 忽略大小写
sorted(words, key=len, reverse=True)   # 按长度降序

records = [("Alice", 30), ("Bob", 25)]
sorted(records, key=lambda r: r[1])    # 按年龄
```

多关键字排序用元组：

```python
sorted(records, key=lambda r: (r[1], r[0]))
```

排序是**稳定**的：相同 key 的元素保持原相对顺序。

### 反转

```python
a = [1, 2, 3]

a.reverse()          # 原地反转 → [3, 2, 1]
b = a[::-1]          # 生成反转后的新列表
c = list(reversed(a))  # 同上
```

## 列表推导式

```python
# 基本
squares = [x ** 2 for x in range(5)]

# 过滤
evens = [x for x in range(10) if x % 2 == 0]

# 条件表达式
labels = ["偶" if x % 2 == 0 else "奇" for x in range(4)]

# 嵌套：先外层后内层
pairs = [(x, y) for x in range(2) for y in range(2)]
# [(0, 0), (0, 1), (1, 0), (1, 1)]

# 展平二维列表
matrix = [[1, 2], [3, 4]]
flat = [x for row in matrix for x in row]   # [1, 2, 3, 4]
```

推导式通常比 `map` / `filter` 更易读：

```python
[str(x) for x in range(3)]              # ['0', '1', '2']
list(map(str, range(3)))                # 等价
[x for x in range(10) if x > 5]         # 比 filter 更直观
```

## 常用内置函数

```python
a = [3, 1, 4, 1, 5]

len(a)          # 5
sum(a)          # 14
sum(a, 10)      # 24，指定起始值
min(a)          # 1
max(a)          # 5
min(a, default=0)   # 空列表时返回默认值

any(x > 4 for x in a)   # True
all(x > 0 for x in a)   # True

list(enumerate(a))      # [(0, 3), (1, 1), ...]
list(zip([1, 2], "ab")) # [(1, 'a'), (2, 'b')]
```

`any` / `all` 会短路，适合做条件判断。

## 复制

```python
import copy

a = [1, [2, 3]]

alias = a              # 别名：同一对象
shallow = a.copy()     # 浅拷贝：外层新列表，内层共享
shallow2 = list(a)     # 同上
shallow3 = a[:]        # 同上
deep = copy.deepcopy(a)  # 深拷贝：递归复制所有层级

shallow[1].append(4)
print(a[1])            # [2, 3, 4]   原列表也被改
print(deep[1])         # [2, 3]      不受影响
```

## 解包

```python
a, b = [1, 2]
first, *rest = [1, 2, 3, 4]     # first=1, rest=[2, 3, 4]
*init, last = [1, 2, 3, 4]      # init=[1, 2, 3], last=4

# 交换
x, y = 1, 2
x, y = y, x
```

函数调用时用 `*` 展开：

```python
def add(a, b, c):
    return a + b + c

nums = [1, 2, 3]
add(*nums)      # 6
```

## 列表作为栈与队列

### 栈（后进先出）

```python
stack = []
stack.append(1)
stack.append(2)
stack.pop()     # 2
```

### 队列（先进先出）

`list.pop(0)` 是 O(n)，元素多时很慢，应使用 `collections.deque`：

```python
from collections import deque

q = deque([1, 2, 3])
q.append(4)      # 右端入队
q.popleft()      # 1，左端出队，O(1)
```

## 性能

| 操作 | 平均复杂度 |
| --- | --- |
| 下标访问 `a[i]` | O(1) |
| 尾部追加 `append` | 摊还 O(1) |
| 尾部弹出 `pop()` | O(1) |
| 头部插入 / 删除 `insert(0, x)` / `pop(0)` | O(n) |
| 中间插入 / 删除 | O(n) |
| `x in a` / `remove` / `index` | O(n) |
| 切片 `a[i:j]` | O(k)，k 为切片长度 |
| 排序 `sort` | O(n log n) |

频繁在头部操作的场景，优先考虑 `deque`。

## 与其它容器对比

| 容器 | 有序 | 可变 | 可重复 | 查找 | 适用场景 |
| --- | --- | --- | --- | --- | --- |
| `list` | 是 | 是 | 是 | O(n) | 顺序存储、下标访问、栈 |
| `tuple` | 是 | 否 | 是 | O(n) | 不可变记录、可哈希 |
| `set` | 否 | 是 | 否 | O(1) | 去重、成员判断 |
| `dict` | 是（3.7+） | 是 | key 唯一 | O(1) | 键值映射 |

需要不可变序列时用 `tuple`；需要快速成员判断时用 `set`；需要键值映射时用 `dict`。

## 与字符串转换

```python
list("abc")                 # ['a', 'b', 'c']
"a,b,c".split(",")          # ['a', 'b', 'c']
",".join(["a", "b", "c"])   # 'a,b,c'

# 数字列表转字符串
",".join(map(str, [1, 2, 3]))   # '1,2,3'

# 字符串转数字列表
list(map(int, "1 2 3".split()))  # [1, 2, 3]
```

`join()` 要求元素全是字符串，混入数字要先 `map(str, ...)`。

## 常见陷阱

1. **`[[0] * 3] * 3` 共享行**：用 `[[0] * 3 for _ in range(3)]`。
2. **`sort()` 返回 `None`**：不要写 `a = a.sort()`，会把列表变成 `None`。
3. **遍历时修改列表**：增删元素会跳过或重复处理，先复制或从后往前遍历。
4. **`remove()` 只删第一个匹配**：删除全部用推导式或 `while x in a: a.remove(x)`。
5. **`a += b` 是原地修改**：有别名时会一起变；`a = a + b` 才创建新列表。
6. **浅拷贝**：嵌套列表仍共享，必要时 `copy.deepcopy()`。
7. **列表不可哈希**：不能作 `dict` key 或 `set` 元素，可改用 `tuple`。
8. **`in` 是 O(n)**：大列表频繁判断改用 `set`。
9. **`pop(0)` 很慢**：用 `deque.popleft()`。
10. **`a == b` 比较内容，`a is b` 比较身份**：不要用 `is` 判断列表相等。
11. **`True` 和 `1` 相等**：`[1] == [True]` 为 `True`。
