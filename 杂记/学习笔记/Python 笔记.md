---
date: 2026-10-04
---
# dataclasses

`dataclasses` 是 Python 3.7+ 标准库。用 `@dataclass` 装饰「以存数据为主」的类，自动生成 `__init__`、`__repr__`、`__eq__` 等方法，省去样板代码。

> 完整讲解与示例见 [[Python dataclasses 库]]。本笔记只作速查。

## 最小示例

```python
from dataclasses import dataclass

@dataclass
class User:
    name: str
    age: int = 0

u = User("Alice", 30)      # User(name='Alice', age=30)
u == User("Alice", 30)     # True
```

字段用 `名称: 类型 = 默认值` 声明，顺序即 `__init__` 参数顺序。

## 自动生成的方法

| 方法 | 作用 | 控制参数 |
| --- | --- | --- |
| `__init__` | 按字段顺序接收参数并赋值给实例 | `init` |
| `__repr__` | 返回 `C(a=1, b=2)` 形式的字符串 | `repr` |
| `__eq__` | 逐字段比较两实例是否相等 | `eq` |
| `__hash__` | 决定是否可哈希（能否进 `set` / 作键） | `eq` / `frozen` / `unsafe_hash` |
| `__lt__` `__le__` `__gt__` `__ge__` | 大小比较 | `order` |
| `__match_args__` | 支持 `match` 模式匹配（3.10+） | `match_args` |
| `__slots__` | 限制实例属性、省内存（3.10+） | `slots` |

### 三者要点

- **`__init__`**：类中已定义则忽略生成；`init=False` 的字段不进参数；**不会调用基类 `__init__`**（需在 `__post_init__` 里手动 `super().__init__()`）。
- **`__repr__`**：`field(repr=False)` 的字段不显示；自定义 `__repr__` 会覆盖生成版本。
- **`__eq__`**：要求两实例**类型完全相同**（子类实例 ≠ 父类实例）；`field(compare=False)` 的字段不参与；3.13 起改为逐字段比较，`nan` 等边界结果可能与旧版不同。

> 注意：这三者（及各方法）若类中已存在，装饰器通常不会覆盖，对应参数被忽略。

## 装饰器参数

| 参数 | 作用 | 默认 |
| --- | --- | --- |
| `init` | 生成 `__init__` | `True` |
| `repr` | 生成 `__repr__` | `True` |
| `eq` | 生成 `__eq__` | `True` |
| `order` | 生成 `<` `<=` `>` `>=` | `False` |
| `unsafe_hash` | 强制生成 `__hash__` | `False` |
| `frozen` | 实例不可变 | `False` |
| `match_args` | 生成 `__match_args__`（3.10+） | `True` |
| `kw_only` | 所有字段强制关键字传参（3.10+） | `False` |
| `slots` | 生成 `__slots__`（3.10+） | `False` |
| `weakref_slot` | 加 `__weakref__` 槽（3.11+，需 `slots=True`） | `False` |

## `field()` 参数

| 参数 | 作用 | 默认 |
| --- | --- | --- |
| `default` | 默认值（不可变对象） | `MISSING` |
| `default_factory` | 工厂函数生成默认值（可变对象） | `MISSING` |
| `init` | 是否作为 `__init__` 参数 | `True` |
| `repr` | 是否出现在 `repr()` 中 | `True` |
| `hash` | 是否参与 `__hash__`（`None` 跟随 `compare`） | `None` |
| `compare` | 是否参与 `==` / 比较 | `True` |
| `metadata` | 只读附加元数据（dataclass 自身不用） | `None` |
| `kw_only` | 该字段强制关键字传参（3.10+） | `MISSING` |
| `doc` | 字段文档字符串（3.14+） | `None` |

## 特性速查

| 特性 | 作用 |
| --- | --- |
| `__post_init__` | `__init__` 结束后自动调用，用于校验 / 派生字段 |
| `frozen=True` | 不可变；赋删字段抛 `FrozenInstanceError` |
| `order=True` | 按字段顺序生成比较方法 |
| `ClassVar` | 标注为类变量，不算字段 |
| `InitVar` | 仅进 `__init__`、传给 `__post_init__`，不保存为字段 |
| `KW_ONLY` | 哨兵，其后的字段全部关键字化 |
| `asdict()` / `astuple()` | 递归转成 `dict` / `tuple`（非容器值会深拷贝） |
| `replace(obj, **changes)` | 基于原对象生成改了部分字段的新对象 |
| `fields()` | 返回 `Field` 元组（不含 `ClassVar` / `InitVar`） |
| `make_dataclass()` | 动态创建数据类 |
| `is_dataclass()` | 判断是否数据类或其实例 |

## 常用片段

```python
from dataclasses import dataclass, field, asdict, replace

# 可变默认值：必须用 default_factory
@dataclass
class Repo:
    items: list = field(default_factory=list)

# 派生字段
@dataclass
class Rect:
    w: float
    h: float
    area: float = field(init=False)
    def __post_init__(self):
        self.area = self.w * self.h

# 不可变 + 可哈希
@dataclass(frozen=True)
class Point:
    x: int
    y: int

# 关键字字段（3.10+）
@dataclass
class Config:
    host: str
    port: int = field(default=8080, kw_only=True)

# 转字典 / 生成新对象
asdict(Point(1, 2))        # {'x': 1, 'y': 2}
replace(Point(1, 2), y=9)  # Point(x=1, y=9)
```

## 注意点

1. **不校验类型**：`User("Alice", "30")` 也合法，注解只是声明。
2. **默认值顺序**：有默认值的字段不能排在无默认值之前，否则 `TypeError`。
3. **可变默认值**：直接写 `items: list = []` 抛 `ValueError`，用 `default_factory`。
4. **默认不可哈希**：`eq=True, frozen=False` 时 `__hash__ = None`，不能进 `set` 或作 `dict` 键。
5. **`order=True` 需 `eq=True`**：否则 `ValueError`；已自定义比较方法再开会 `TypeError`。
6. **`frozen` 不改内层可变性**：列表字段仍可 `append`。
7. **`replace()` 会重跑 `__init__` / `__post_init__`**，`init=False` 字段被重算而非复制。
8. **`asdict()` 是深拷贝**：大对象有性能开销。
9. **`slots=True` 不能动态加属性**；类中已有 `__slots__` 会 `TypeError`。
10. **子类也要加 `@dataclass`**，否则不会处理新字段。
