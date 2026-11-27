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
  - "[[python/python库/Python json 库]]"
---

# Python 列表

`list` 是 Python 最常用的容器：**可变、有序、可重复**，底层是动态数组。按下标访问 O(1)，尾部追加摊还 O(1)，中间插入或删除要搬移后续元素，O(n)。元素可以是任意类型，也可以嵌套。

它同时也是「引用语义」最容易踩坑的地方：赋值不复制、复制只拷一层、原地方法返回 `None`。下面先立 5 条铁律，其余按「创建 → 访问 → 修改 → 复制 → 查找 → 遍历 → 排序 → 推导」展开，末尾有速查表与陷阱清单。

## 语义铁律

1. **变量是引用**：`b = a` 之后两个名字指向同一个列表，改一个另一个也变。
2. **复制默认只拷第一层**：`a.copy()`、`list(a)`、`a[:]` 都是浅拷贝，嵌套的列表仍然共享。
3. **原地方法返回 `None`**：`sort()`、`append()`、`extend()`、`reverse()` 都不要接返回值。
4. **尾部快、中间慢**：`append` / `pop()` 摊还 O(1)；`insert(0, x)`、`pop(0)`、`del a[i]` 要搬移元素，O(n)。
5. **元素任意、可重复、不可哈希**：`[1, "a", None, 1]` 合法；列表不能作 `dict` 的 key 或放进 `set`；空列表为假。

## 创建

```python
a1 = []                          # 空列表
a2 = list()                      # 同上
a3 = [1, 2, 3]                   # 字面量
a4 = list(range(5))              # [0, 1, 2, 3, 4]
a5 = list("abc")                 # ['a', 'b', 'c']
a6 = [0] * 5                     # [0, 0, 0, 0, 0]
a7 = [x * 2 for x in range(3)]   # [0, 2, 4]
```

`list()` 接受任何可迭代对象：元组、字符串、字典的键、生成器、`range`。

乘法创建适合**不可变元素**；元素可变时，放进去的是同一个对象：

```python
bad = [[0] * 3] * 3
bad[0][0] = 1
bad      # [[1, 0, 0], [1, 0, 0], [1, 0, 0]]  三行是同一个列表

good = [[0] * 3 for _ in range(3)]
good[0][0] = 1
good     # [[1, 0, 0], [0, 0, 0], [0, 0, 0]]
```

> [!warning] `[x] * n` 只复制引用
> 它把**同一个对象**放进去 n 次。需要 n 个独立对象时用推导式 `[x for _ in range(n)]`，嵌套结构的共享问题见「别名与复制」。

## 访问与切片

```python
a = [10, 20, 30, 40, 50]

a[0]        # 10
a[-1]       # 50
a[1:4]      # [20, 30, 40]   左闭右开
a[3:]       # [40, 50]
a[::2]      # [10, 30, 50]
a[::-1]     # [50, 40, 30, 20, 10]
a[100:]     # []             切片越界不报错
# a[100]    # IndexError     只有下标访问才报错
```

负步长时，start 仍表示起点、stop 仍不含，只是方向反过来：

```python
a[5:1:-1]   # [50, 40, 30]   起点 5 被截到末尾
a[1:4:-1]   # []             方向与切片方向矛盾，结果为空
a[::0]      # ValueError: slice step cannot be zero
```

切片**返回新列表**，但只拷第一层：

```python
b = a[:]
b[0] = 999
a[0]          # 10，原列表不受影响
b[1] is a[1]  # True，元素本身是同一个对象
```

切片赋值可以改长度，也可以用来删除：

```python
a = [1, 2, 3, 4]
a[1:3] = [20, 30, 40]
a           # [1, 20, 30, 40, 4]
a[1:2] = []
a           # [1, 30, 40, 4]    赋空列表 = 删除该区间
a[::2] = [7, 8]   # 带步长时必须等长，否则 ValueError
del a[::2]        # 也可以按步长删除
```

## 修改

### 添加

```python
a = [1, 2]

a.append(3)         # [1, 2, 3]                追加“一个对象”
a.append([4, 5])    # [1, 2, 3, [4, 5]]        列表被当成一个元素塞进去
a.extend([4, 5])    # [1, 2, 3, [4, 5], 4, 5]  逐个元素追加
a.insert(2, 2.5)    # [1, 2, 2.5, 3, [4, 5], 4, 5] 添加在下标2前
a.insert(99, 9)     # 越界不报错，等于 append
a.insert(-99, -1)   # 越界不报错，等于插到最前
a += [7, 8]         # 原地扩展，id 不变
```

- `append` 加一个对象，`extend` 把可迭代对象逐个加：`a.extend("ab")` 得到 `['a', 'b']`，`a.append("ab")` 得到 `['ab']`。
- `extend` 接受任何可迭代对象，生成器也行。
- `insert(i, x)` 是 O(n)；下标越界时夹到两端处理，**不抛异常**。
- `a += b` 等价于 `a.extend(b)`，**原地修改**；`a = a + b` 才创建新列表。`a *= 2` 同理。

### 删除

```python
a = [10, 20, 30, 20]

a.remove(20)   # 按值删第一个 → [10, 30, 20]；找不到抛 ValueError
a.pop()        # 30       默认弹出最后一个
a.pop(0)       # 10       按下标弹出，O(n)
# [].pop()     # IndexError
del a[0]       # 按下标删除
del a[1:3]     # 按切片删除
a.clear()      # 清空，等价 del a[:]
```

- `remove` 按值、`pop` 按下标、`del` 是语句而不是方法。
- `pop` 越界和空列表都会 `IndexError`。
- 想删除**所有**匹配元素，用推导式重建（见「遍历」），不要循环 `remove`。

### 改值

```python
a = [1, 2, 3]
a[0] = 100        # [100, 2, 3]
a[1:3] = [20, 30]
a[1:3] = []       # 借切片赋值删除
```

## 别名与复制

```python
import copy

a = [1, [2, 3]]

alias = a                 # 别名：同一个对象
shallow = a.copy()        # 浅拷贝：新外壳
shallow2 = list(a)        # 同上
shallow3 = a[:]           # 同上
deep = copy.deepcopy(a)   # 深拷贝：递归复制
```

| 写法 | 新对象 | 内层是否共享 | 用途 |
| ---- | ---- | ---- | ---- |
| `b = a` | 否 | 是（就是同一个） | 传参、临时引用 |
| `a.copy()` / `list(a)` / `a[:]` | 是 | 是 | 只改外层元素时 |
| `copy.deepcopy(a)` | 是 | 否 | 嵌套结构要独立修改 |

```python
shallow[0] = 999       # 不影响 a
shallow[1].append(4)   # 影响 a：a[1] 变成 [2, 3, 4]
deep[1].append(5)      # 不影响 a
```

变量只是对象的标签，赋值复制的是标签而不是对象：`id(a) == id(alias)` 为 `True`，而 `id(shallow) != id(a)`。

## 查找与判断

```python
a = [10, 20, 30, 20]

a.index(20)         # 1   首次出现的下标
a.index(20, 2)      # 3   从下标 2 开始找
a.index(20, 0, 2)   # 1   end 不含
a.index(20, -2)     # 3   start 可以是负数
# a.index(99)       # ValueError

a.count(20)         # 2   没有 start / end 参数
20 in a             # True
99 not in a         # True
```

- `index()` 找不到抛 `ValueError`，**不是**返回 `-1`（这点与 `str.find` 不同）；不确定时先 `in`。
- `count()` 只接受一个参数，想统计区间要先切片。
- `x in a`、`remove`、`index` 都是 O(n)，大列表高频判断改用 `set`。
- `==` 逐元素比较内容，`is` 比较是不是同一个对象。

## 遍历与解包

### 遍历

```python
for x in a: ...
for i, x in enumerate(a, start=1): ...   # 需要下标时用它，别用 range(len(a))
for x, y in zip(a, b): ...               # 长度不等时截断到最短
for x in reversed(a): ...                # 返回迭代器，不复制列表
```

一边遍历一边增删会跳过元素：

```python
a = [1, 2, 2, 3]
for x in a:
    if x == 2:
        a.remove(x)
a        # [1, 2, 3]  第二个 2 被跳过，没删掉
```

两种正确写法：

```python
# 1) 推导式重建（最直观）
a = [x for x in a if x != 2]

# 2) 倒序遍历，按下标删
for i in range(len(a) - 1, -1, -1):
    if a[i] == 2:
        del a[i]
```

> [!warning] 遍历时不要改长度
> 列表迭代器只记着「走到第几个下标」，删除后元素前移，下一个下标就被跳过；插入则可能重复处理。多线程下 `list` 也不是同步容器。

### 解包

```python
a, b = [1, 2]
first, *rest = [1, 2, 3, 4]      # first=1, rest=[2, 3, 4]
*init, last = [1, 2, 3, 4]       # init=[1, 2, 3], last=4

x, y = 1, 2
x, y = y, x                      # 交换
```

- 不带星号时元素个数必须完全匹配，否则 `ValueError`。
- 解包适用于任何可迭代对象，不限于列表。
- 函数调用时用 `*` 展开：`add(*[1, 2, 3])`；字典用 `**`。

## 排序与反转

```python
a = [3, 1, 2]

a.sort()               # 原地排序：a 变成 [1, 2, 3]，返回值是 None

b = sorted(a)          # 返回新列表，a 不变
```

`key` 指定排序依据，`reverse` 控制方向：

```python
words = ["Apple", "banana", "Cherry"]
sorted(words)                         # 大写字母排在前
sorted(words, key=str.lower)          # 忽略大小写
sorted(words, key=len, reverse=True)  # 按长度降序

records = [("Alice", 30), ("Bob", 25)]
sorted(records, key=lambda r: r[1])          # 按年龄
sorted(records, key=lambda r: (r[1], r[0]))  # 多关键字：先年龄后名字
```

- 排序**稳定**：key 相同的元素保持原相对顺序，所以「先按名字排、再按年龄排」能实现多级排序。
- `key` 对每个元素**只调用一次**，比较的是返回值。
- 列表里混入不可比较的类型（如同时有 `int` 和 `str`）会抛 `TypeError`。
- 底层是 Timsort，O(n log n)；对已部分有序的数据很快。

反转：

```python
a = [1, 2, 3]

a.reverse()            # 原地反转，返回 None
b = a[::-1]            # 新列表
c = list(reversed(a))  # 迭代器转列表
```

## 列表推导式

```python
[x ** 2 for x in range(5)]                     # 基本
[x for x in range(10) if x % 2 == 0]           # 过滤
["偶" if x % 2 == 0 else "奇" for x in range(4)]  # 条件表达式

[(x, y) for x in range(2) for y in range(2)]   # 嵌套：外层 x 在前，得 (0,0)(0,1)(1,0)(1,1)

matrix = [[1, 2], [3, 4]]
[x for row in matrix for x in row]             # 展平 → [1, 2, 3, 4]
```

- 嵌套顺序与 `for` 的书写顺序一致，等价于同名的嵌套循环。
- 推导式里的变量不泄漏到外层（Python 3）。
- 需要就地修改原列表时用普通 `for`；推导式用来**生成新列表**。

## 速查

### 方法总表

| 方法 | 作用 | 返回 | 复杂度 |
| ---- | ---- | ---- | ---- |
| `append(x)` | 尾部追加一个对象 | `None` | 摊还 O(1) |
| `extend(it)` | 逐个追加可迭代对象 | `None` | O(k) |
| `insert(i, x)` | 在下标 i 处插入 | `None` | O(n) |
| `remove(x)` | 删除第一个等于 x 的元素 | `None` | O(n) |
| `pop([i])` | 弹出下标 i（默认 -1） | 被弹出的元素 | 尾部 O(1)，其余 O(n) |
| `clear()` | 清空 | `None` | O(n) |
| `index(x[, s[, e]])` | 首次出现的下标 | `int` | O(n) |
| `count(x)` | 出现次数 | `int` | O(n) |
| `sort(key=, reverse=)` | 原地排序 | `None` | O(n log n) |
| `reverse()` | 原地反转 | `None` | O(n) |
| `copy()` | 浅拷贝 | 新列表 | O(n) |

### 常用内置函数

```python
a = [3, 1, 4, 1, 5]

len(a)              # 5
sum(a)              # 14
sum(a, 10)          # 24，第二个参数是起始值
min(a)              # 1
max(a)              # 5
max(["fig", "apple"], key=len)   # 'apple'，key 自定义比较依据
min([], default=0)  # 空列表时给默认值，否则 ValueError

any(x > 4 for x in a)   # True
all(x > 0 for x in a)   # True
```

- `min` / `max` 支持 `key`、`default`，`sum` 支持起始值；`any` / `all` 会短路。

### 复杂度

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

### 与其他容器对比

| 容器 | 有序 | 可变 | 可重复 | 查找 | 适用场景 |
| --- | --- | --- | --- | --- | --- |
| `list` | 是 | 是 | 是 | O(n) | 顺序存储、下标访问、栈 |
| `tuple` | 是 | 否 | 是 | O(n) | 不可变记录、可哈希 |
| `set` | 否 | 是 | 否 | O(1) | 去重、成员判断 |
| `dict` | 是（3.7+） | 是 | key 唯一 | O(1) | 键值映射 |

需要不可变序列时用 `tuple`，需要快速成员判断时用 `set`，需要键值映射时用 `dict`。

### 与字符串互转

```python
list("abc")                      # ['a', 'b', 'c']
"a,b,c".split(",")               # ['a', 'b', 'c']
",".join(["a", "b", "c"])        # 'a,b,c'

",".join(map(str, [1, 2, 3]))    # '1,2,3'        数字列表先转字符串
list(map(int, "1 2 3".split()))  # [1, 2, 3]      字符串转数字列表
```

`join()` 要求元素全是字符串，混入数字要先 `map(str, ...)`。

### 栈与队列

栈（后进先出）直接用列表：

```python
stack = []
stack.append(1)
stack.append(2)
stack.pop()      # 2
```

队列（先进先出）不要用 `list.pop(0)`——它是 O(n)。用 `collections.deque`：

```python
from collections import deque

q = deque([1, 2, 3])
q.append(4)      # 右端入队
q.popleft()      # 1，左端出队，O(1)
```

## 常见陷阱

1. **`a = a.sort()`**：原地方法返回 `None`，列表被换成 `None`；用 `sorted(a)`。
2. **`b = a` 当成复制**：改 `b` 会连带改 `a`，复制用 `a.copy()`。
3. **浅拷贝嵌套仍共享**：`a.copy()` 只拷第一层，嵌套要 `copy.deepcopy()`。
4. **遍历时增删**：正序 `remove` / `del` 会跳过元素，用推导式重建或倒序遍历。
5. **`True` 与 `1` 相等**：`[1] == [True]` 为 `True`，混合布尔与数字的去重、判断会出错。
6. **用 `is` 比较列表**：`[1] is [1]` 内容相同也是两个对象，结果 `False`，列表相等用 `==`。
7. **可变默认参数**：`def f(x=[])` 的默认列表跨调用共享，函数内 `append` 会累积；默认值改 `None`，进函数再 `if x is None: x = []`。
8. **大列表里循环 `in` / `remove`**：每次 O(n)，合起来 O(n²)，先建 `set` 或用推导式。
9. **`pop(0)` 当队列**：O(n)，元素一多就慢，改用 `deque.popleft()`。

## 参考来源

- [Python 教程：数据结构（lists 一节）](https://docs.python.org/3/tutorial/datastructures.html)
- [内置类型：list](https://docs.python.org/3/library/stdtypes.html#list)
- [通用序列操作](https://docs.python.org/3/library/stdtypes.html#common-sequence-operations)
- [copy — 浅拷贝与深拷贝](https://docs.python.org/3/library/copy.html)
- [collections.deque](https://docs.python.org/3/library/collections.html#collections.deque)

## 相关笔记

- [[Python 字典]] — 键值映射，与列表互为补充的容器
- [[Python 字符串]] — 文本序列与 `split` / `join`
- [[Python进阶阶段学习规划表]] — 数据结构与算法的学习路径
- [[Python json 库]] — 列表与 JSON 数组的序列化
