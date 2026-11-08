---
title: Python 字典
date: 2026-11-01
tags:
  - Python
  - 字典
  - 教程
aliases:
  - Python dict
  - Python 字典操作
  - dict
related:
  - "[[python/Python 字符串]]"
  - "[[python/python库/Python json 库]]"
  - "[[python/Python进阶阶段学习规划表]]"
---

# Python 字典

Python 的字典类型是 `dict`，一种**键值对（key-value）映射**。它支持按 key 快速查找、插入和删除，平均时间复杂度为 O(1)，是 Python 中最常用的数据结构之一。

自 Python 3.7 起，`dict` **保证保持插入顺序**；key 必须是可哈希（hashable）的对象。

## 核心要点

- key 必须**可哈希**：`str`、`int`、`float`、`tuple`（元素也可哈希）、`frozenset` 等；`list`、`dict`、`set` 不能作 key。
- `d[key]` 在 key 不存在时抛 `KeyError`；不确定时用 `d.get(key, default)`。
- `in` 判断的是 **key**，不是 value；判断 value 需要遍历或反向索引。
- 3.7+ 保持插入顺序；`reversed(d)` 可反向迭代（3.8+）。
- `d.keys()` / `d.values()` / `d.items()` 返回**动态视图**，会反映字典后续变化。
- 合并字典可用 `|`（3.9+）、`{**a, **b}` 或 `update()`，右边覆盖左边。
- `.copy()` 是**浅拷贝**；嵌套可变对象需要 `copy.deepcopy()`。
- 遍历时不要增删 key，否则抛 `RuntimeError: dictionary changed size during iteration`。

## 创建字典

```python
d1 = {}
d2 = dict()
d3 = {"a": 1, "b": 2}
d4 = dict(a=1, b=2)                 # 关键字形式，key 必须是合法标识符
d5 = dict([("a", 1), ("b", 2)])     # 由键值对序列创建
d6 = dict(zip(["a", "b"], [1, 2]))  # 配合 zip
d7 = {x: x ** 2 for x in range(3)}  # 字典推导式

print(d7)   # {0: 0, 1: 1, 2: 4}
```

`dict.fromkeys()` 用一组 key 创建字典：

```python
dict.fromkeys(["a", "b"], 0)        # {'a': 0, 'b': 0}
dict.fromkeys(["a", "b"])           # {'a': None, 'b': None}
```

注意：第二个参数是**同一个对象**，如果传可变对象，所有 key 会共享它：

```python
d = dict.fromkeys(["a", "b"], [])
d["a"].append(1)
print(d)        # {'a': [1], 'b': [1]}   ← 共享同一个列表
```

需要独立列表时用推导式：`{k: [] for k in ["a", "b"]}`。

## 访问与修改

```python
d = {"name": "Alice", "age": 30}

d["name"]              # 'Alice'
# d["email"]           # KeyError

d.get("email")         # None
d.get("email", "")     # ''
d.get("age", 0)        # 30

d["email"] = "a@example.com"   # 新增
d["age"] = 31                  # 修改
del d["email"]                 # 删除，不存在则 KeyError

d.pop("age")                   # 31，同时删除
d.pop("missing", 0)            # 0，不存在时返回默认值
d.popitem()                    # 删除并返回最后一个键值对（LIFO）
d.clear()                      # 清空
```

### `setdefault()`：取不到就设默认值

```python
d = {}
d.setdefault("count", 0)       # 0，并写入 d["count"]
d.setdefault("count", 100)     # 0，已存在则不改

# 常见用法：分组
groups = {}
for word in ["apple", "avocado", "banana"]:
    groups.setdefault(word[0], []).append(word)
# {'a': ['apple', 'avocado'], 'b': ['banana']}
```

## 判断与遍历

```python
d = {"a": 1, "b": 2}

"a" in d            # True      判断 key
1 in d              # False     不是判断 value
len(d)              # 2

for key in d:                    # 直接迭代得到 key
    print(key)

for key in d.keys():
    print(key)

for value in d.values():
    print(value)

for key, value in d.items():
    print(key, value)
```

视图是动态的：

```python
keys = d.keys()
d["c"] = 3
print(keys)         # dict_keys(['a', 'b', 'c'])
```

遍历时修改：

```python
# 错误：RuntimeError
# for k in d:
#     del d[k]

# 正确：先复制一份
for k in list(d):
    if k == "a":
        del d[k]
```

## 常用方法速查

| 方法 | 作用 |
| --- | --- |
| `d.keys()` | 返回所有 key 的视图 |
| `d.values()` | 返回所有 value 的视图 |
| `d.items()` | 返回 `(key, value)` 视图 |
| `d.get(k[, default])` | 取 key，不存在返回默认值 |
| `d.setdefault(k[, default])` | 存在则返回，不存在则写入并返回 |
| `d.pop(k[, default])` | 删除并返回，不存在可给默认值 |
| `d.popitem()` | 删除并返回最后一个键值对 |
| `d.update(other)` | 用另一个映射/键值对更新 |
| `d.clear()` | 清空 |
| `d.copy()` | 浅拷贝 |
| `dict.fromkeys(iterable[, value])` | 由 key 序列创建字典 |

`keys()` / `items()` 视图支持集合运算：

```python
d1 = {"a": 1, "b": 2}
d2 = {"b": 3, "c": 4}

d1.keys() & d2.keys()   # {'b'}
d1.keys() | d2.keys()   # {'a', 'b', 'c'}
d1.keys() - d2.keys()   # {'a'}
```

## 合并字典

```python
a = {"x": 1, "y": 2}
b = {"y": 3, "z": 4}

# 3.9+：合并运算符
c = a | b               # {'x': 1, 'y': 3, 'z': 4}
a |= b                  # 原地合并

# 传统写法
c = {**a, **b}          # 右边覆盖左边
c = a.copy()
c.update(b)
```

重复 key 以**右边**为准。

## 字典推导式

```python
squares = {x: x ** 2 for x in range(5)}
# {0: 0, 1: 1, 2: 4, 3: 9, 4: 16}

# 过滤
even = {k: v for k, v in squares.items() if v % 2 == 0}

# 反转键值
pairs = {"a": 1, "b": 2}
reversed_pairs = {v: k for k, v in pairs.items()}
# {1: 'a', 2: 'b'}

# 转换 value
prices = {"apple": 3, "banana": 2}
discounted = {k: v * 0.9 for k, v in prices.items()}
```

推导式里也可以嵌套：

```python
matrix = {i: {j: i * j for j in range(3)} for i in range(3)}
```

## 排序

字典本身按插入顺序迭代；需要排序时先生成排序后的 `items()`：

```python
d = {"b": 2, "a": 1, "c": 3}

dict(sorted(d.items()))                       # 按 key 排序
dict(sorted(d.items(), key=lambda kv: kv[1])) # 按 value 排序
dict(sorted(d.items(), key=lambda kv: kv[1], reverse=True))

sorted(d, key=d.get)                          # key 列表，按 value 排序
```

## 默认值与计数

### `collections.defaultdict`

访问不存在的 key 时自动创建默认值：

```python
from collections import defaultdict

groups = defaultdict(list)
for word in ["apple", "avocado", "banana"]:
    groups[word[0]].append(word)

counts = defaultdict(int)
for ch in "hello":
    counts[ch] += 1
# defaultdict(<class 'int'>, {'h': 1, 'e': 1, 'l': 2, 'o': 1})
```

### `collections.Counter`

专门用于计数：

```python
from collections import Counter

c = Counter("hello")
# Counter({'l': 2, 'h': 1, 'e': 1, 'o': 1})

c.most_common(2)       # [('l', 2), ('h', 1)]
c["l"]                 # 2
c["x"]                 # 0，不存在的 key 返回 0
```

### `collections.OrderedDict`

3.7 之后普通 `dict` 已保持顺序，`OrderedDict` 主要多了 `move_to_end()` 等能力：

```python
from collections import OrderedDict

od = OrderedDict([("a", 1), ("b", 2)])
od.move_to_end("a")    # {'b': 2, 'a': 1}
```

## 嵌套字典

```python
users = {
    "alice": {"age": 30, "city": "Beijing"},
    "bob": {"age": 25, "city": "Shanghai"},
}

users["alice"]["age"]            # 30
users["alice"]["email"] = "a@example.com"

# 安全地创建多层结构
users.setdefault("carol", {}).setdefault("tags", []).append("new")
```

深层合并需要自己写递归函数，或使用 `mergedeep` 等第三方库。

## 复制：浅拷贝与深拷贝

```python
import copy

d = {"a": [1, 2]}

alias = d              # 同一对象
shallow = d.copy()     # 浅拷贝：外层新字典，内层列表仍共享
deep = copy.deepcopy(d)  # 深拷贝：递归复制所有层级

shallow["a"].append(3)
print(d["a"])          # [1, 2, 3]   原字典也变了
print(deep["a"])       # [1, 2]      不受影响
```

`{**d}`、`dict(d)`、`d | {}` 都是浅拷贝。

## 键的哈希规则

作为 key 的对象必须实现 `__hash__()` 且不可变（或至少哈希值不变）：

```python
d = {}
d[(1, 2)] = "tuple"        # 可以
d[frozenset({1, 2})] = "set"  # 可以
# d[[1, 2]] = "list"       # TypeError: unhashable type: 'list'
```

容易踩坑的等价 key：

```python
d = {}
d[1] = "int"
d[True] = "bool"       # 1 == True，覆盖同一个 key
d[1.0] = "float"       # 1 == 1.0，仍然同一个 key

print(d)               # {1: 'float'}
```

自定义对象作 key 时，需要同时实现 `__hash__()` 和 `__eq__()`，并保证相等的对象哈希值相同。

## 性能与适用场景

| 操作 | 平均复杂度 |
| --- | --- |
| 按 key 取值 `d[k]` | O(1) |
| 插入 / 删除 | O(1) |
| `k in d` | O(1) |
| 遍历 | O(n) |
| `v in d.values()` | O(n) |

- 需要**按 key 快速查找** → `dict`
- 只需要判断元素是否存在、去重 → `set`
- 需要有序序列、按下标访问 → `list`
- 需要计数 → `Counter`
- 需要多值映射 → `defaultdict(list)`

字典的内存开销高于列表，海量小数据时要注意。

## 解包与函数调用

```python
def greet(name, age):
    print(f"{name}, {age}")

info = {"name": "Alice", "age": 30}
greet(**info)          # 等价于 greet(name="Alice", age=30)

merged = {**info, "city": "Beijing"}
```

`*d` 迭代的是 key：

```python
d = {"a": 1, "b": 2}
print(*d)              # a b
```

## 与 JSON 的关系

`dict` 与 JSON 对象天然对应，但 JSON 的 key 必须是字符串：

```python
import json

data = {"name": "Alice", "age": 30}
text = json.dumps(data, ensure_ascii=False)
back = json.loads(text)
```

`json.dumps({1: "a"})` 会把整数 key 转成字符串 `"1"`。详见 [[python/python库/Python json 库]]。

## 常见陷阱

1. **`KeyError`**：不确定 key 是否存在时用 `get()` 或 `in`。
2. **`in` 判断的是 key**：`1 in {"a": 1}` 是 `False`，要判断 value 需遍历。
3. **`fromkeys` 共享可变默认值**：`dict.fromkeys(keys, [])` 会让所有 key 指向同一个列表。
4. **遍历时增删 key**：先 `list(d.items())` 复制再操作。
5. **浅拷贝不等于深拷贝**：嵌套可变对象仍会共享。
6. **`1`、`True`、`1.0` 是同一个 key**：哈希值相同且相等。
7. **别名赋值**：`d2 = d1` 不会复制，修改互相影响。
8. **依赖插入顺序前先确认版本**：3.7+ 才有语言层面保证。
9. **可变对象不能作 key**：列表、字典、集合都不行。
10. **`popitem()` 的顺序**：3.7+ 为 LIFO（后进先出），旧版本行为不确定。
