---
title: Python dataclasses 库
date: 2026-10-04
tags:
  - Python
  - dataclasses
  - 数据类
  - 教程
aliases:
  - Python dataclass
  - dataclasses 模块
  - Python 数据类
related:
  - "[[Pydantic]]"
  - "[[models目录]]"
  - "[[用 Python 搭建复杂项目]]"
  - "[[Python json 库]]"
  - "[[单元测试]]"
---

# Python dataclasses 库

`dataclasses` 是 Python 3.7 起提供的标准库，用于给「以存储数据为主」的类自动生成 `__init__()`、`__repr__()`、`__eq__()` 等特殊方法，从而消除大量样板代码。它源自 [PEP 557](https://peps.python.org/pep-0557/)，**无需安装**，是数据载体、配置对象、DTO、值对象最常用的建模方式。

本笔记聚焦 `dataclasses` 的 API 与实战。它与 [[Pydantic]] 的关键区别是：`dataclasses` **只根据类型注解生成代码，不在运行时校验类型**；需要校验、解析、序列化时应选择 Pydantic。

## 核心要点

- `@dataclass` 自动生成 `__init__` / `__repr__` / `__eq__`，字段顺序即参数顺序。
- 类型注解只用于**声明**，`dataclass` 默认不做运行时类型检查（仅 `ClassVar` / `InitVar` 例外会被识别）。
- 可变默认值必须用 `field(default_factory=...)`，否则抛 `ValueError`。
- `frozen=True` 模拟不可变；`eq=True` 且 `frozen=True` 时自动可哈希。
- 常用工具：`field()`、`asdict()`、`astuple()`、`replace()`、`fields()`、`make_dataclass()`。
- 需要数据校验 / JSON 解析用 [[Pydantic]]；纯数据载体优先 `dataclass`。

## 最小示例

```python
from dataclasses import dataclass

@dataclass
class InventoryItem:
    """库存项。"""
    name: str
    unit_price: float
    quantity_on_hand: int = 0

    def total_cost(self) -> float:
        return self.unit_price * self.quantity_on_hand

item = InventoryItem("widget", 3.0, 10)
print(item)                # InventoryItem(name='widget', unit_price=3.0, quantity_on_hand=10)
print(item.total_cost())   # 30.0
print(item == InventoryItem("widget", 3.0, 10))  # True
```

等价于手写了 `__init__(self, name, unit_price, quantity_on_hand=0)`，并逐一 `self.x = x`。

字段通过「类型注解 + 赋值」声明，**顺序即 `__init__` 的参数顺序**，也是 `repr`、比较、`fields()` 的顺序。

## 自动生成的方法

| 方法 | 由哪个参数控制 | 默认 | 说明 |
| ---- | ---- | ---- | ---- |
| `__init__` | `init` | 生成 | 类已定义则忽略该参数 |
| `__repr__` | `repr` | 生成 | 形如 `C(a=1, b=2)` |
| `__eq__` | `eq` | 生成 | 仅同类实例可比较；逐字段比较（3.13 起） |
| `__lt__`/`__le__`/`__gt__`/`__ge__` | `order` | 不生成 | 按字段顺序当作元组比较 |
| `__hash__` | `unsafe_hash` / `frozen` / `eq` | 视情况 | 见下文「哈希」 |
| `__match_args__` | `match_args` | 生成 | 支持 `match` 模式匹配（3.10+） |
| `__slots__` | `slots` | 不生成 | 返回新类（3.10+） |

## 装饰器参数

| 参数 | 作用 | 默认 |
| ---- | ---- | ---- |
| `init` | 生成 `__init__` | `True` |
| `repr` | 生成 `__repr__` | `True` |
| `eq` | 生成 `__eq__` | `True` |
| `order` | 生成比较方法 | `False` |
| `unsafe_hash` | 强制生成 `__hash__` | `False` |
| `frozen` | 实例不可变 | `False` |
| `match_args` | 生成 `__match_args__`（3.10+） | `True` |
| `kw_only` | 所有字段强制关键字传参（3.10+） | `False` |
| `slots` | 生成 `__slots__`（3.10+） | `False` |
| `weakref_slot` | 加 `__weakref__` 槽（3.11+，需 `slots=True`） | `False` |

```python
@dataclass
class C:
    ...

@dataclass()
class C:
    ...

# 三种写法完全等价
@dataclass(init=True, repr=True, eq=True, order=False, unsafe_hash=False,
           frozen=False, match_args=True, kw_only=False, slots=False,
           weakref_slot=False)
class C:
    ...
```

> [!warning] `order=True` 与 `eq=False` 不能共存
> 会抛 `ValueError`。`order=True` 依赖 `eq=True`；另外若类中已自定义 `__lt__` 等方法，`order=True` 会抛 `TypeError`。

## 默认值与字段规则

```python
@dataclass
class Point:
    x: int
    y: int = 0

Point(1)        # Point(x=1, y=0)
Point(1, 5)     # Point(x=1, y=5)
```

规则：

- **有默认值的字段必须排在无默认值字段之后**，无论同一类内还是继承导致，违反抛 `TypeError`。
- 若想规避顺序限制，可把后续字段标为 `kw_only`（见下文）。
- 用 `field()` 的字段，其类属性会被替换为 `default`；未提供 `default` 时该属性会被删除。

## `field()` 参数

`field()` 为单个字段补充配置。

| 参数 | 作用 | 默认 |
| ---- | ---- | ---- |
| `default` | 默认值（不可变对象适用） | `MISSING` |
| `default_factory` | 用零参可调用对象生成默认值（可变对象适用） | `MISSING` |
| `init` | 是否作为 `__init__` 参数 | `True` |
| `repr` | 是否出现在 `repr()` 中 | `True` |
| `hash` | 是否参与 `__hash__`；`None` 时跟随 `compare` | `None` |
| `compare` | 是否参与 `==` 及大小比较 | `True` |
| `metadata` | 只读映射，供第三方扩展使用，dataclass 自身不用 | `None` |
| `kw_only` | 该字段强制关键字传参（3.10+） | `MISSING` |
| `doc` | 字段文档字符串（3.14+） | `None` |

`default` 与 `default_factory` 互斥，同时指定会报错。

### 可变默认值：`default_factory`

直接用可变对象作默认值会抛 `ValueError`：

```python
@dataclass
class Bad:
    items: list = []   # ValueError: mutable default <class 'list'> ... not allowed
```

正确做法是用工厂函数，每次实例化都调用一次，实例间互不影响：

```python
from dataclasses import dataclass, field

@dataclass
class Good:
    items: list = field(default_factory=list)
    config: dict = field(default_factory=dict)

a, b = Good(), Good()
a.items.append(1)
print(a.items, b.items)   # [1] []
```

> [!note] 3.11 起判定标准变化
> 早期只禁止 `list`/`dict`/`set`；3.11 起改为「**不可哈希（unhashable）即视为可变**，不允许作默认值」。所以自定义可变对象也会被拦截。

### `init=False`：不进构造函数

```python
import time
from dataclasses import dataclass, field

@dataclass
class Task:
    name: str
    created_at: float = field(default_factory=time.time, init=False)

Task("learn")           # created_at 由工厂自动生成，不能传入
```

注意：`init=False` 且带 `default_factory` 时，**工厂函数总会在 `__init__` 中被调用**（因为没别的机会赋初值）。

### `repr=False` 与 `compare=False`

```python
@dataclass
class Point:
    x: int
    y: int
    secret: str = field(default="", repr=False, compare=False)

p1 = Point(1, 2, secret="a")
p2 = Point(1, 2, secret="b")
print(p1)         # Point(x=1, y=2)  —— secret 不显示
print(p1 == p2)   # True  —— secret 不参与比较
```

### `metadata`：附加元数据

```python
@dataclass
class Product:
    name: str
    price: float = field(metadata={"unit": "CNY", "min": 0})

print(Product.__dataclass_fields__["price"].metadata)
# {'unit': 'CNY', 'min': 0}
```

`metadata` 会包裹成只读的 `MappingProxyType`，dataclass 本身不读取它，纯粹留给第三方（如校验框架、序列化器）作命名空间。

### `doc`：字段文档（3.14+）

```python
@dataclass
class User:
    name: str = field(doc="用户显示名")
```

## `__post_init__`：初始化后处理

生成的 `__init__` 结束时会调用 `self.__post_init__()`（若存在），常用于校验、派生字段、调用基类初始化：

```python
from dataclasses import dataclass, field

@dataclass
class Rectangle:
    width: float
    height: float
    area: float = field(init=False)

    def __post_init__(self):
        self.area = self.width * self.height

Rectangle(3, 4).area   # 12.0
```

若显式关闭 `init`（`init=False`），则 `__post_init__` 不会被自动调用。

> [!tip] 基类不是 dataclass 时
> 生成的 `__init__` 不会调用基类的 `__init__`。若基类有必须执行的初始化，可在 `__post_init__` 中手动 `super().__init__(...)`。

## 类变量与仅初始化变量

### `ClassVar`：类变量，不算字段

```python
from typing import ClassVar
from dataclasses import dataclass

@dataclass
class Config:
    kind: ClassVar[str] = "config"   # 不进 __init__、不算字段
    name: str
```

`ClassVar` 标注的变量会被 `fields()` 忽略。

### `InitVar`：仅用于初始化，不保存为字段

`InitVar[T]` 描述的值会作为 `__init__` 参数，并传给 `__post_init__`，但**不会成为实例字段**，也不被 `fields()` 返回：

```python
from dataclasses import dataclass, InitVar

@dataclass
class C:
    i: int
    j: int | None = None
    database: InitVar[object | None] = None

    def __post_init__(self, database):
        if self.j is None and database is not None:
            self.j = database.lookup("j")

C(10, database=my_db)
```

多个 `InitVar` 会按声明顺序传给 `__post_init__`。

## 可变性、哈希与比较

### `frozen=True`：不可变实例

```python
@dataclass(frozen=True)
class Coord:
    x: int
    y: int

c = Coord(1, 2)
# c.x = 10   # dataclasses.FrozenInstanceError: cannot assign to field 'x'
```

`frozen=True` 会生成 `__setattr__` / `__delattr__`，赋删属性时抛 `FrozenInstanceError`（`AttributeError` 子类）。它只是「模拟」不可变，仍有轻微性能开销（内部用 `object.__setattr__` 初始化）。

> [!warning] 与自定义 `__setattr__` 冲突
> 若类中已定义 `__setattr__` / `__delattr__`，再设 `frozen=True` 会抛 `TypeError`。
> 另外，`frozen` 不会让可变字段（如 `list`）本身不可变，只是禁用属性重新绑定。

### `__hash__` 生成规则

| 条件 | 结果 |
| ---- | ---- |
| `eq=True`, `frozen=True` | 生成 `__hash__`（可哈希） |
| `eq=True`, `frozen=False` | `__hash__ = None`（不可哈希，因可变） |
| `eq=False` | 不干预，沿用父类（默认按 `id`） |
| `unsafe_hash=True` | 强制生成（即使可变，慎用） |

> [!warning] 常见坑
> 默认 `@dataclass`（`eq=True, frozen=False`）的实例**不可哈希**，不能放进 `set` 或作 `dict` 键。想当键用，要么 `frozen=True`，要么 `eq=False`，或自定义 `__hash__`。

### `order=True`：可比较

```python
@dataclass(order=True)
class Version:
    major: int
    minor: int

Version(1, 2) < Version(2, 0)   # True
```

比较时按字段声明顺序当作元组逐个比。可用 `field(compare=False)` 排除某些字段：

```python
@dataclass(order=True)
class Item:
    price: float
    name: str = field(compare=False)   # 不参与比较
```

## 关键字字段（keyword-only）

三种方式：

```python
# 1) 整个数据类
@dataclass(kw_only=True)
class A:
    host: str
    port: int = 8080

# 2) 单个字段
@dataclass
class B:
    host: str
    port: int = field(default=8080, kw_only=True)

# 3) KW_ONLY 哨兵：其后的字段全部关键字化
from dataclasses import KW_ONLY

@dataclass
class Point:
    x: float
    _: KW_ONLY
    y: float
    z: float

Point(0, y=1.5, z=2.0)   # 正确
# Point(0, 1.5, 2.0)     # TypeError
```

生成的 `__init__` 会把关键字参数统一挪到普通参数之后；关键字字段也不进入 `__match_args__`。同一类中 `KW_ONLY` 只能出现一次。

## `slots=True`：省内存

```python
@dataclass(slots=True)
class Point:
    x: int
    y: int
```

`slots=True`（3.10+）会生成 `__slots__` 并返回**一个新的类**，实例不再有 `__dict__`，内存占用更小、属性访问略快，但**不能动态添加属性**。

- 若类中已有 `__slots__`，会抛 `TypeError`。
- 想支持弱引用需 `weakref_slot=True`（3.11+），且必须同时 `slots=True`。
- 与 `__init_subclass__` 传参一起使用有已知限制（见 CPython gh-91126）。
- 不要用 `__slots__` 反推字段名，请用 `fields()`。

## 常用工具函数

| 函数 | 作用 |
| ---- | ---- |
| `fields(class_or_instance)` | 返回 `Field` 元组（不含 `ClassVar`/`InitVar`） |
| `asdict(obj, *, dict_factory=dict)` | 递归转成嵌套 `dict`，非容器对象用 `deepcopy` |
| `astuple(obj, *, tuple_factory=tuple)` | 递归转成嵌套 `tuple` |
| `replace(obj, /, **changes)` | 基于原对象生成替换了部分字段的新对象 |
| `is_dataclass(obj)` | 判断是否数据类或其实例 |
| `make_dataclass(name, fields, ...)` | 动态创建数据类 |
| `MISSING` / `KW_ONLY` | 哨兵值 |

```python
from dataclasses import dataclass, asdict, astuple, replace, fields, is_dataclass

@dataclass
class Point:
    x: int
    y: int

@dataclass
class Line:
    start: Point
    end: Point

line = Line(Point(0, 0), Point(10, 4))

asdict(line)    # {'start': {'x': 0, 'y': 0}, 'end': {'x': 10, 'y': 4}}
astuple(line)   # ((0, 0), (10, 4))
replace(line, end=Point(5, 5))   # Line(start=Point(x=0, y=0), end=Point(x=5, y=5))

[f.name for f in fields(Point)]   # ['x', 'y']
is_dataclass(line)                # True
```

> [!warning] `asdict()` 是深拷贝
> 会递归 `deepcopy` 非 dataclass/dict/list/tuple 的值，`replace()` 会重新走 `__init__`（因此 `__post_init__` 会再次执行，且 `init=False` 字段不会被复制，而是重新生成）。

### 浅拷贝

```python
{name: getattr(obj, name) for name in (f.name for f in fields(obj))}
```

### 动态创建 `make_dataclass()`

```python
from dataclasses import make_dataclass, field

C = make_dataclass(
    "C",
    [("x", int), "y", ("z", int, field(default=5))],
    namespace={"add_one": lambda self: self.x + 1},
)
C(1, "anything", z=9).add_one()   # 2
```

每个字段可以是 `name`、`(name, type)` 或 `(name, type, Field)`；只给 `name` 时类型为 `typing.Any`。3.14 新增 `decorator` 参数可替换 `@dataclass`。

### `replace()` 与 `copy.replace()`

`replace()` 会调用 `__init__`，`init=False` 字段被重新初始化而非复制，且不能在 `changes` 中指定。dataclass 实例也支持标准库 `copy.replace()`。

## `Field` 与反射

`Field` 由 `fields()` 返回，不应手动实例化。公开属性：`name`、`type`、`default`、`default_factory`、`init`、`repr`、`hash`、`compare`、`metadata`、`kw_only`。

```python
@dataclass
class User:
    name: str
    age: int

for f in fields(User):
    print(f.name, f.type, f.default)   # name <class 'str'> MISSING ...
```

`__dataclass_fields__` 是类上的字段映射，键为字段名。可用于自省、生成 schema、通用序列化。

## 序列化：与 JSON 配合

`asdict()` 常与标准库 `json` 搭配：

```python
import json
from dataclasses import dataclass, asdict, field
from datetime import datetime

@dataclass
class Event:
    name: str
    at: datetime = field(default_factory=datetime.now)

e = Event("deploy")
json.dumps(asdict(e), ensure_ascii=False, default=str)   # datetime 需 default 处理
```

反序列化需自己写工厂 / hook（见 [[Python json 库]]）。若需要严格的解析与校验，直接用 [[Pydantic]] 更省事。

## 与 Pydantic / NamedTuple / attrs 对比

| 维度 | `dataclass` | [[Pydantic]] | `NamedTuple` | `attrs` |
| ---- | ---- | ---- | ---- | ---- |
| 来源 | 标准库 | 第三方 | 标准库 | 第三方 |
| 运行时类型校验 | ❌ | ✅ | ❌ | 可选 |
| 可变性 | 可选 `frozen` | `frozen=True` | 不可变 | 可选 |
| 序列化 | 需 `asdict` + 手写 | 内置 JSON / Schema | `_asdict()` | 内置 |
| 性能 | 轻 | 校验有开销（V2 由 Rust 加速） | 轻 | 轻 |
| 适用 | 纯数据载体、配置、值对象 | API / 校验 / 解析 | 轻量不可变元组 | 功能更全的 dataclass 替代 |

选择建议：项目内部、无需校验的数据结构用 `dataclass`；对外接口、需要校验和序列化时用 [[Pydantic]]。参见 [[models目录]] 的模型层方案对比。

## 常见陷阱

1. **可变默认值**：`x: list = []` 抛 `ValueError`，必须用 `default_factory`。
2. **默认值顺序**：有默认值的字段不能排在无默认值字段前面，继承时同样生效。
3. **默认不可哈希**：`eq=True, frozen=False` 时 `__hash__` 被置 `None`，进不了 `set`/`dict`。
4. **类型注解不校验**：`User("Alice", "not-an-int")` 完全合法，需要校验就得靠 Pydantic 或自身 `__post_init__`。
5. **忘记子类也要加 `@dataclass`**：子类只写类型注解不会自动生成/继承生成逻辑，需显式装饰。
6. **`frozen` 不改内层可变性**：列表字段仍可 `append`；真正不可变需 `tuple`/`frozenset`。
7. **`replace()` 触发副作用**：会重新调用 `__init__` 和 `__post_init__`，`init=False` 字段被重算。
8. **`asdict()` 深拷贝开销**：大对象或含非容器对象时注意性能与身份丢失。
9. **`slots=True` 不能动态加属性**：与缓存、动态注入等写法冲突。
10. **`__eq__` 要求同类**：`dataclass` 之间即使字段相同，父子类实例也不相等；3.13 起逐字段比较，`nan` 等边界结果可能与旧版不同。
11. **`order=True` 需 `eq=True`**：否则 `ValueError`；自定义了比较方法再开 `order` 会 `TypeError`。

## 最佳实践

- 值对象 / 坐标 / 配置用小而专用的 `frozen=True` 数据类。
- 大量实例（成千上万）时考虑 `slots=True` 省内存。
- 敏感字段用 `repr=False`，派生字段用 `init=False` + `__post_init__`。
- 需要校验、解析、JSON Schema 时选 [[Pydantic]]，不要手写一堆 `__post_init__` 校验。
- 保持数据类「纯粹」：只存数据与简单派生，业务逻辑放到 service 层（见 [[models目录]]）。
- 对外序列化统一走 `asdict()` + [[Python json 库]]，或 Pydantic 的 `model_dump_json()`。
- 给字段写 `doc`（3.14+）便于生成文档与 IDE 提示。

## 版本演进

| 版本 | 变化 |
| ---- | ---- |
| 3.7 | 模块引入（PEP 557） |
| 3.10 | `slots`、`kw_only`、`match_args`、`KW_ONLY`、`field(kw_only=)` |
| 3.11 | `weakref_slot`；可变默认值判定改为「不可哈希即禁止」 |
| 3.13 | `__eq__` 改为逐字段比较（此前是比较字段元组），更快但 `nan` 等边界结果可能不同 |
| 3.14 | `field(doc=...)` 字段文档；`make_dataclass(decorator=...)` |

## 参考来源

- [dataclasses — Data Classes（Python 官方文档）](https://docs.python.org/3/library/dataclasses.html)
- [PEP 557 — Data Classes](https://peps.python.org/pep-0557/)
- [PEP 526 — Syntax for Variable Annotations](https://peps.python.org/pep-0526/)
- [copy.replace()](https://docs.python.org/3/library/copy.html#copy.replace)

## 相关笔记

- [[Pydantic]] — 带运行时校验与序列化的数据建模
- [[models目录]] — 项目模型层选型（Pydantic vs dataclass vs ORM）
- [[用 Python 搭建复杂项目]] — 数据类在分层架构中的位置
- [[Python json 库]] — `asdict()` 后的序列化与反序列化
- [[单元测试]] — 用 `==` 与 `replace()` 简化测试构造
