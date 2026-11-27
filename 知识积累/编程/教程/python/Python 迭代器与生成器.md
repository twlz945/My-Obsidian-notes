---
title: Python 迭代器与生成器
date: 2026-11-21
tags:
  - Python
  - 迭代器
  - 生成器
  - 教程
aliases:
  - Python 迭代器
  - 生成器
  - iterator
  - generator
related:
  - "[[python/Python 列表]]"
  - "[[python/Python 字典]]"
  - "[[python/Python 文件读写]]"
  - "[[python/Python进阶阶段学习规划表]]"
---

# Python 迭代器与生成器

迭代器是 Python 的**惰性序列协议**：`for`、推导式、解包、`zip`、`sum`、文件逐行、数据库游标，底层都是「拿一个 `iter()`，反复 `next()`，直到 `StopIteration`」。

要讲清它只需要抓住两件事：**可迭代对象和迭代器不是一回事**，以及**生成器是用函数写迭代器的最省事方式**。前者决定你能不能重复遍历，后者决定你写出来的代码有多短。

本笔记基于 CPython 3.14 实测，字节码与输出都来自本机。

## 语义铁律

1. **可迭代对象有 `__iter__`，迭代器有 `__next__`**：迭代器一定是可迭代对象，反之不成立。
2. **迭代器是一次性的**：耗尽后再遍历得到空，不会自动重置。
3. **`for` 的本质**是 `iter()` → 反复 `next()` → 捕获 `StopIteration`。
4. **生成器函数调用时不执行函数体**：返回生成器对象，第一次 `next` 才开始跑。
5. **惰性不等于免费**：省内存，但不能 `len()` / 索引 / 重复遍历，每次取元素还有一层帧切换开销。

## 可迭代对象 vs 迭代器

| | 可迭代对象 Iterable | 迭代器 Iterator |
| --- | --- | --- |
| 必须实现 | `__iter__` | `__iter__` + `__next__` |
| 典型例子 | `list`、`str`、`dict`、`set`、`range` | 生成器、`iter(list)`、文件对象、`map`/`filter` 的返回值 |
| 能否重复遍历 | 能，每次 `iter()` 造一个新迭代器 | 不能，走完即空 |
| `iter(x) is x` | `False` | `True` |
| 类型检查 | `isinstance(x, collections.abc.Iterable)` | `isinstance(x, collections.abc.Iterator)` |

```python
import collections.abc as abc

it = iter([1, 2])
isinstance([1], abc.Iterable)   # True
isinstance([1], abc.Iterator)   # False
isinstance(it, abc.Iterator)    # True
iter(it) is it                  # True，迭代器的 __iter__ 返回自身
```

几个容易忽略的事实：

- `iter(x)` 先找 `__iter__`；**没有 `__iter__` 但有 `__getitem__`** 时，会退化成「旧式序列协议」，从下标 0 开始取到 `IndexError` 为止。
- **`list` 不实现 `__next__`**，正是为了让它可以被反复遍历：每次 `for` 都造一个新的 `list_iterator`。
- **文件对象是迭代器**：`iter(f) is f` 为 `True`，所以文件只能被 `for` 读一遍，读完再读是空的（见「常见陷阱」）。

## `for` 到底做了什么

`for x in obj` 等价于：

```python
it = iter(obj)
while True:
    try:
        x = next(it)
    except StopIteration:
        break
    # 循环体
```

编译成字节码时，核心是 `GET_ITER` 和 `FOR_ITER`（3.14 实测，省略了缓存与跳转细节）：

```text
LOAD_CONST    (1, 2, 3)
GET_ITER
FOR_ITER      -> 循环体
STORE_FAST    x
JUMP_BACKWARD -> FOR_ITER
END_FOR
```

`FOR_ITER` 就是「带异常处理的 `next`」：取到值就继续，抛 `StopIteration` 就跳到循环外。所以：

- **`StopIteration` 在 `for` 里被吞掉**，你在循环外看不到它；手写 `while + next()` 才需要自己 `try`。
- **`for ... else`**：`else` 只在循环正常结束（没被 `break`）时执行。
- **生成器里 `raise StopIteration` 会变成 `RuntimeError`**（PEP 479），因为 `StopIteration` 在生成器内部有特殊含义，见「常见陷阱」。

旧式协议兜底——只有 `__getitem__` 也能被 `for`：

```python
class Old:
    def __getitem__(self, i):
        if i >= 3:
            raise IndexError
        return i * 10

list(Old())     # [0, 10, 20]，iter() 自动包装成迭代器
```

## 手写迭代器

实现 `__iter__` 和 `__next__` 两个方法即可：

```python
class Countdown:
    def __init__(self, start):
        self.current = start

    def __iter__(self):
        return self                 # 迭代器的 __iter__ 返回自身

    def __next__(self):
        if self.current <= 0:
            raise StopIteration     # 唯一的终止信号
        self.current -= 1
        return self.current + 1


list(Countdown(3))                  # [3, 2, 1]
```

要点：

- **状态放在实例属性里**，`__next__` 每次推进一格。
- **终止只能 `raise StopIteration`**，`return None` 不是终止，`None` 是合法元素。
- **忘写 `__iter__`** 会得到 `TypeError: 'Countdown' object is not iterable`。
- 迭代器耗尽后再 `next` 仍应继续抛 `StopIteration`（上面的写法自然满足）。

### 容器类和迭代器类要分开

| | 容器（可重复遍历） | 迭代器（一次性） |
| --- | --- | --- |
| `__iter__` | 返回**新的**迭代器 | 返回 `self` |
| `__next__` | 不实现 | 实现 |
| 例子 | `list`、自定义 `Bag` | `Countdown`、生成器 |

```python
class Bag:
    def __init__(self, items):
        self._items = list(items)

    def __iter__(self):
        return iter(self._items)    # 每次给一个新迭代器，所以能反复遍历
```

把两者混在一个类里（`__iter__` 返回 `self` 又带状态），就会得到一个「只能遍历一次」的容器——这通常不是调用方想要的。

### `iter(callable, sentinel)`

`iter()` 的第二个参数是「一直调用 callable，直到返回值等于 sentinel」：

```python
with open("data.bin", "rb") as f:
    for block in iter(lambda: f.read(8), b""):
        process(block)              # 每次读 8 字节，读完为止
```

这是少数不需要写 `__iter__` 就能造迭代器的场景，适合「重复调用直到某个值」的接口。

## 生成器

含 `yield` 的函数就是生成器函数，调用它不会执行函数体，而是返回一个生成器对象：

```python
def countdown(n):
    print("开始")            # 第一次 next 才执行
    while n > 0:
        yield n              # 产出值并挂起
        n -= 1

g = countdown(3)             # 什么都不打印
next(g)                      # 打印「开始」，返回 3
next(g)                      # 2
next(g)                      # 1
next(g)                      # StopIteration
```

执行模型：

- 第一次 `next` 从函数开头跑到第一个 `yield`，**挂起**，保留局部变量和指令位置。
- 之后每次 `next` 从挂起处**恢复**，跑到下一个 `yield`。
- 函数返回（或 `return`）时抛 `StopIteration`，迭代结束。

生成器把「手写两个方法 + 维护状态」压缩成了「写一个循环 + `yield`」，状态就是局部变量。

### 生成器表达式

```python
squares = (x * x for x in range(5))    # 圆括号：生成器表达式
squares                                # <generator object ...>
list(squares)                          # [0, 1, 4, 9, 16]
list(squares)                          # []，已经耗尽
```

| | 列表推导式 `[...]` | 生成器表达式 `(...)` |
| --- | --- | --- |
| 求值 | 立即，全部算完 | 惰性，取一个算一个 |
| 内存 | 存所有结果 | 只存当前状态 |
| 可重复遍历 | 可以 | 不行 |
| 能 `len` / 索引 | 可以 | 不行 |

作为函数的唯一参数时可以省括号：

```python
sum(x * x for x in range(100))     # 不用写 sum((...))
```

## 生成器进阶

### `send`：让 `yield` 有返回值

`yield` 是表达式，`send(value)` 恢复执行并把 `value` 作为 `yield` 的值：

```python
def accumulator():
    total = 0
    while True:
        x = yield total          # 收到 send 的值
        if x is None:
            break
        total += x

g = accumulator()
next(g)          # 0，启动到第一个 yield
g.send(10)       # 10
g.send(5)        # 15
```

- **启动只能用 `next(g)` 或 `g.send(None)`**；直接 `send(非 None)` 抛 `TypeError`。
- `next(g)` 等价于 `g.send(None)`。
- 这是「生成器当轻量协程」的基础：调用方和生成器可以双向传值。

### `throw` / `close` / `GeneratorExit`

```python
def guarded():
    try:
        yield 1
    except ValueError:
        yield "捕获到 ValueError"
    finally:
        print("清理")

g = guarded()
next(g)                 # 1
g.throw(ValueError)     # '捕获到 ValueError'，异常在挂起点抛出
g.close()               # 触发 GeneratorExit，finally 执行
```

- `throw(exc)` 在挂起点抛出异常，生成器可以捕获并继续 `yield`。
- `close()` 在挂起点抛 `GeneratorExit`；生成器**捕获后若继续 `yield`，会抛 `RuntimeError`**，正确做法是清理后退出。
- `finally` 一定会执行，所以 `close()` 适合释放资源。
- `inspect.getgeneratorstate(g)` 可查状态：`GEN_CREATED` / `GEN_SUSPENDED` / `GEN_RUNNING` / `GEN_CLOSED`。

### `yield from`：委托给子迭代器

```python
def inner():
    yield "a"
    return 99

def outer():
    result = yield from inner()     # 委托迭代，并接住子生成器的返回值
    print("inner 返回", result)
    yield "b"

list(outer())    # inner 返回 99；['a', 'b']
```

- `yield from` 会把 `next` / `send` / `throw` **转发**给子迭代器，`close` 也会传递。
- 子生成器 `return` 的值成为 `yield from` 表达式的值。
- 拍平嵌套结构比手写循环短：

```python
def flatten(nested):
    for item in nested:
        if isinstance(item, list):
            yield from flatten(item)
        else:
            yield item

list(flatten([1, [2, [3, 4]], 5]))   # [1, 2, 3, 4, 5]
```

### `return` 在生成器里意味着什么

```python
def gen():
    yield 1
    return 42

g = gen()
next(g)          # 1
try:
    next(g)
except StopIteration as e:
    print(e.value)   # 42
```

`return value` 结束生成器，并把 `value` 塞进 `StopIteration.value`。`for` 循环拿不到这个值，只有 `yield from` 或手动捕获 `StopIteration` 才能取到。

## 常用模式

### 管道：读 → 过滤 → 转换

```python
def read_lines(path):
    with open(path, encoding="utf-8") as f:
        yield from f

def strip(lines):
    for line in lines:
        yield line.strip()

def non_empty(lines):
    for line in lines:
        if line:
            yield line

for line in non_empty(strip(read_lines("data.txt"))):
    print(line)
```

每一层都只做一件事，全部惰性，大文件也不会一次性读进内存。

### 无限序列 + `islice` 截断

```python
import itertools

def naturals():
    n = 0
    while True:
        yield n
        n += 1

list(itertools.islice(naturals(), 5))    # [0, 1, 2, 3, 4]
```

生成器可以「无限」，因为只在你取的时候才计算；但**永远不要**对无限生成器调用 `list()` / `sum()`。

### 分批处理

```python
import itertools

def chunks(iterable, size):
    it = iter(iterable)
    while batch := list(itertools.islice(it, size)):
        yield batch

list(chunks(range(7), 3))    # [[0, 1, 2], [3, 4, 5], [6]]
```

3.12+ 可以直接用 `itertools.batched(data, 3)`，返回元组。

### 短路：`any` / `all` 提前结束

```python
def is_prime(n):
    if n < 2:
        return False
    return all(n % i for i in range(2, int(n ** 0.5) + 1))
```

`all` 遇到第一个假值就停，后面的除数根本不会算——这是生成器「按需计算」最直接的收益。

## `itertools` 常用表

| 函数 | 作用 | 示例 |
| --- | --- | --- |
| `chain(a, b)` | 串联多个可迭代对象 | `list(chain([1, 2], "ab"))` → `[1, 2, 'a', 'b']` |
| `islice(it, n)` | 截取前 n 个（不支持负数） | `list(islice(count(), 3))` → `[0, 1, 2]` |
| `count(start, step)` | 无限计数 | `islice(count(10, 2), 4)` → `[10, 12, 14, 16]` |
| `cycle(it)` | 无限循环 | `islice(cycle("AB"), 5)` → `['A', 'B', 'A', 'B', 'A']` |
| `repeat(x, n)` | 重复 n 次 | `list(repeat("x", 3))` |
| `tee(it, n)` | 复制成 n 个独立迭代器 | 消耗内存，慎用 |
| `groupby(it, key)` | 按 key 分组，**只合并相邻** | 先排序再分组 |
| `pairwise(it)` | 相邻两两配对（3.10+） | `list(pairwise([1, 2, 3]))` → `[(1, 2), (2, 3)]` |
| `batched(it, n)` | 分批（3.12+） | `list(batched("ABCDEFG", 3))` |
| `zip_longest(a, b)` | 按最长补齐 | 对比内置 `zip` 截断 |
| `accumulate(it)` | 累积和 / 自定义函数 | `list(accumulate([1, 2, 3]))` → `[1, 3, 6]` |
| `product` / `permutations` / `combinations` | 笛卡尔积、排列、组合 | 全量返回，注意体积 |

> [!warning] `groupby` 只合并相邻元素
> `groupby("ABAB")` 会得到 4 组而不是 2 组。要按 key 全局分组，先 `sorted()` 再 `groupby`。

## 性能与内存

```python
import sys

lst = [i for i in range(100_000)]
gen = (i for i in range(100_000))

sys.getsizeof(lst)    # 约 0.76 MB，只是指针数组，还没算元素对象
sys.getsizeof(gen)    # 200 字节
```

用 `tracemalloc` 看实际分配：创建 10 万元素的生成器时约 0.4 KB，全部消费完仍不到 1 KB。

| 维度 | 列表 | 生成器 |
| --- | --- | --- |
| 内存 | 与元素数成正比 | 基本恒定（200 字节左右） |
| 启动速度 | 立即算完 | 立即返回，算到才做 |
| 遍历速度 | 略快 | 每次 `next` 有帧切换开销 |
| 随机访问 | O(1) | 不支持 |
| 重复遍历 | 支持 | 不支持 |

结论：

- **数据量大、只需要顺序处理一次** → 生成器（日志、大文件、流式 API）。
- **需要多次遍历、随机访问、排序、切片** → 列表（`sorted()` 对生成器会先全部载入，等于没省）。
- **不要为了「省内存」把三五行的小循环改成生成器**，可读性收益通常为负。

## 常见陷阱

1. **迭代器耗尽后再遍历是空的**：`list(g)` 之后再 `list(g)` 得到 `[]`，需要重新创建。
2. **文件对象是迭代器**：`for` 读完一遍就到底，想重读要 `f.seek(0)`，或者干脆重新 `open`。
3. **生成器函数体延迟执行**：函数里的异常、打印、副作用都要等到第一次 `next` 才发生，调试时容易误判。
4. **`return x` 不给 `for` 返回值**：只能通过 `StopIteration.value` 或 `yield from` 拿到。
5. **生成器里 `raise StopIteration` 变成 `RuntimeError`**（PEP 479），因为它会被误认为正常结束。
6. **`next(it)` 没有默认值**：耗尽后 `StopIteration` 直接冒泡，用 `next(it, default)` 兜底。
7. **闭包延迟绑定**：把 `lambda` 存进列表后统一调用，`x` 是循环结束时的值；用默认参数 `lambda x=x: x` 固定。
8. **遍历时修改容器**：`dict` 增删 key 抛 `RuntimeError: dictionary changed size during iteration`；`list` 更隐蔽，会跳过元素。
9. **`map` / `filter` / `zip` 在 Python 3 返回迭代器**，只能消费一次；需要复用先 `list()`。
10. **生成器不能 `len()`、索引、切片、`pickle`**：`TypeError` 提示它没有 `__len__` / 不可序列化。
11. **同一个生成器传给两个消费者**：先消费的一方把元素吃光，另一方拿到空序列。

## 参考来源

- [Python 教程：迭代器与生成器](https://docs.python.org/3/tutorial/classes.html#iterators)
- [数据模型：`__iter__` / `__next__`](https://docs.python.org/3/reference/datamodel.html#object.__iter__)
- [表达式：`yield` 与 `yield from`](https://docs.python.org/3/reference/expressions.html#yieldexpr)
- [PEP 234 — Iterators](https://peps.python.org/pep-0234/)
- [PEP 255 — Simple Generators](https://peps.python.org/pep-0255/)
- [PEP 380 — `yield from`](https://peps.python.org/pep-0380/)
- [PEP 479 — StopIteration 与生成器](https://peps.python.org/pep-0479/)
- [itertools — 迭代器函数](https://docs.python.org/3/library/itertools.html)

## 相关笔记

- [[Python 列表]] — 最常用的可迭代对象，`reversed` / `enumerate` 返回迭代器
- [[Python 字典]] — 遍历得到的是 key，`items()` 视图也是可迭代对象
- [[Python 文件读写]] — 文件对象本身是迭代器，适合逐行读取
- [[Python进阶阶段学习规划表]] — 数据结构与算法的学习路径
