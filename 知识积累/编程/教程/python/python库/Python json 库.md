---
title: Python json 库
date: 2026-10-03
tags:
  - Python
  - JSON
  - 教程
aliases:
  - Python json 模块
  - json 标准库
related:
  - "[[JSON]]"
  - "[[Pydantic]]"
  - "[[API]]"
---

# Python json 库

Python 标准库 `json` 提供 JSON 的序列化（Python 对象 → JSON 文本）与反序列化（JSON 文本 → Python 对象）能力。它是标准库的一部分，**无需安装**，是与 [[API]]、配置文件、日志、跨语言数据交换打交道时最常用的模块之一。本笔记聚焦 Python `json` 的 API 与实战用法；JSON 格式本身见 [[JSON]]。

## 核心要点

- 四个核心函数：`dumps` / `loads` 处理字符串，`dump` / `load` 处理文件对象。
- 中文必须配合 `ensure_ascii=False`，否则会被转义成 `\uXXXX`。
- 自定义对象序列化用 `default=`（或 `JSONEncoder` 子类）；反序列化成对象用 `object_hook=`。
- 默认允许 `NaN` / `Infinity`（**非标准 JSON**），对外接口建议设 `allow_nan=False`。
- 标准库由 C 实现（`_json`）加速；超大吞吐或极致性能场景可换 `orjson` / `msgspec` / `ujson`。

## 四个核心函数

| 函数 | 方向 | 输入 / 输出 |
| ---- | ---- | ---- |
| `json.dumps(obj)` | Python 对象 → JSON 文本 | 返回 `str` |
| `json.loads(s)` | JSON 文本 → Python 对象 | 接收 `str` / `bytes` / `bytearray`，返回对象 |
| `json.dump(obj, fp)` | Python 对象 → 文件 | 内部调用 `fp.write()` |
| `json.load(fp)` | 文件 → Python 对象 | 内部调用 `fp.read()` |

## 最小示例

```python
import json

# 序列化：Python 对象 -> JSON 字符串
data = {"name": "张三", "age": 28, "skills": ["Python", "C"]}
text = json.dumps(data, ensure_ascii=False, indent=2)
print(text)
# {
#   "name": "张三",
#   "age": 28,
#   "skills": ["Python", "C"]
# }

# 反序列化：JSON 字符串 -> Python 对象
obj = json.loads(text)
print(obj["name"], type(obj["age"]))  # 张三 <class 'int'>
```

## 类型映射

**JSON → Python**

| JSON | Python |
| ---- | ------ |
| object | `dict` |
| array | `list` |
| string | `str` |
| number (整数) | `int` |
| number (小数) | `float` |
| true / false | `True` / `False` |
| null | `None` |

**Python → JSON**

| Python | JSON |
| ------ | ---- |
| `dict` | object |
| `list`、`tuple` | array |
| `str` | string |
| `int`、`float` | number |
| `True` / `False` | true / false |
| `None` | null |

> [!warning] 注意
> `set`、`datetime`、`Decimal`、自定义类等默认无法序列化，会抛 `TypeError`，需配合 `default=` 处理。`tuple` 会被序列化成数组，反序列化回来是 `list`（类型不守恒）。

## 常用参数

### 输出美化与体积控制

- `indent`：缩进。整数表示空格数，也可传字符串（如 `"\t"`）；`None` 表示紧凑单行。
- `separators`：分隔符。默认 `(', ', ': ')`；有 `indent` 时默认 `(',', ': ')`。要最小体积用 `(',', ':')`。
- `sort_keys=True`：按键名排序，便于 diff 与稳定输出。
- `ensure_ascii`：默认 `True`，非 ASCII 字符转义为 `\uXXXX`；中文场景设 `False`。

```python
json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True)
json.dumps(data, separators=(",", ":"))  # 紧凑，适合网络传输
```

### 反序列化行为控制

- `object_hook(d)`：每解析完一个 JSON 对象就调用，返回值替代该 `dict`，常用于还原成自定义对象。
- `object_pairs_hook(pairs)`：与 `object_hook` 类似，但接收键值对列表，可检测重复键。
- `parse_float` / `parse_int`：自定义数字解析，例如用 `decimal.Decimal`。
- `parse_constant`：处理 `-Infinity`、`Infinity`、`NaN` 三个非标准字面量。

```python
import decimal

json.loads('{"price": 1.1}', parse_float=decimal.Decimal)
# {'price': Decimal('1.1')}
```

### 容错与循环引用

- `default(obj)`：遇到不可序列化对象时调用，返回可序列化值；无法处理则抛 `TypeError`。
- `skipkeys=True`：跳过键不是 `str`/`int`/`float`/`bool`/`None` 的项，而不是报错。
- `check_circular`：默认 `True`，检测循环引用；关闭有栈溢出风险。
- `allow_nan`：默认 `True`；设 `False` 后 `NaN`/`Infinity` 会抛 `ValueError`。

## 文件读写

```python
import json

data = {"名称": "示例", "值": 42}

# 写入：务必显式指定 UTF-8
with open("data.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

# 读取：显式指定编码
with open("data.json", "r", encoding="utf-8") as f:
    loaded = json.load(f)
```

> [!tip] 经验
> - 写文件时 `ensure_ascii=False` 与 `encoding="utf-8"` 要成对出现，否则中文可能乱码或仍被转义。
> - `json.loads` 会自动探测 `bytes` 输入的编码（UTF-8/16/32），但读文本文件时仍建议显式声明 `encoding`。

## 序列化自定义对象

### 方式一：`default`

```python
from datetime import datetime

def to_json(obj):
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError(f"不支持的类型: {type(obj)}")

json.dumps({"time": datetime.now()}, default=to_json, ensure_ascii=False)
```

### 方式二：继承 `JSONEncoder`

```python
class MyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, set):
            return sorted(obj)
        return super().default(obj)

json.dumps({"tags": {"b", "a"}}, cls=MyEncoder)
```

### 反序列化为对象

```python
from dataclasses import dataclass, asdict

@dataclass
class Point:
    x: int
    y: int

p = Point(1, 2)
s = json.dumps(asdict(p))                       # 序列化

def hook(d):
    if {"x", "y"} <= d.keys():
        return Point(**d)
    return d

json.loads(s, object_hook=hook)                 # Point(x=1, y=2)
```

使用 [[Pydantic]] 时通常不需要手写 hook：`model_dump_json()` 直接序列化，`Model.model_validate_json(s)` 直接反序列化并做校验。

## 异常处理

```python
try:
    data = json.loads(text)
except json.JSONDecodeError as e:
    print(e.msg, "位置", e.pos, "行", e.lineno, "列", e.colno)
```

`json.JSONDecodeError` 是 `ValueError` 的子类，携带 `msg`、`doc`、`pos`、`lineno`、`colno`，适合定位错误位置。

## 命令行工具

标准库自带 `json.tool`，可用于校验和格式化 JSON：

```bash
python -m json.tool data.json
python -m json.tool data.json --indent 2 --sort-keys
python -m json.tool data.json --no-ensure-ascii
python -m json.tool --json-lines data.jsonl   # 每行一个 JSON（Python 3.8+）
```

## 性能与替代库

| 库 | 特点 | 适用场景 |
| -- | ---- | -------- |
| `json`（标准库） | 零依赖，C 加速，够快 | 绝大多数场景 |
| `orjson` | Rust 实现，速度快、默认输出 UTF-8 `bytes` | 高吞吐 API、日志 |
| `msgspec` | 极快，支持类型化结构体 | 需要 schema/校验的高性能场景 |
| `ujson` | C 实现，API 接近标准库 | 简单替换提速 |
| `simplejson` | 标准库的超集，含 `Decimal` 等支持 | 需要更多特性的场景 |

> [!tip] JSONL / 流式
> 超大数组不适合一次性 `load`。常用做法是 **JSON Lines**：每行一个独立 JSON 对象，逐行 `json.loads` 处理，内存友好。

## 常见陷阱

1. **中文被转义**：忘记 `ensure_ascii=False`，输出成 `\u4e2d\u6587`。
2. **单引号不是合法 JSON**：`"{'a': 1}"` 会解析失败，必须双引号。
3. **`True`/`False`/`None` vs `true`/`false`/`null`**：序列化结果是小写 JSON 字面量，反序列化回来才是 Python 值。
4. **元组变列表**：`tuple` 往返后成为 `list`。
5. **键必须可哈希且为字符串**：键为 `int` 时会被转成字符串；对象键需 `skipkeys` 或 `default`。
6. **重复键静默覆盖**：默认后者覆盖前者，需要检测时用 `object_pairs_hook`。
7. **`NaN`/`Infinity` 非标准**：Python 能读写，但跨语言可能被拒，对外建议 `allow_nan=False`。
8. **`default=str` 掩盖问题**：会把所有不可序列化对象变成字符串，反序列化后无法还原。
9. **大文件内存溢出**：一次性 `load` 大文件会占满内存，考虑流式/JSONL。

## 最佳实践

- 对外 API 统一用 `ensure_ascii=False` + UTF-8，保证中文可读。
- 需要稳定 diff 的配置/快照，加 `sort_keys=True` 与固定 `indent`。
- 不要用 `eval()` 解析 JSON，`json.loads` 本身不执行代码，更安全。
- 自定义类型成对设计「序列化 + 反序列化」，避免只做单向。
- 校验数据结构时优先 [[Pydantic]] 等工具，而不是手写 `object_hook`。
- 网络传输用紧凑分隔符（`separators=(",", ":")`）减小体积。

## 参考来源

- [json — JSON encoder and decoder（Python 官方文档）](https://docs.python.org/3/library/json.html)
- [RFC 8259 — The JavaScript Object Notation (JSON) Data Interchange Format](https://www.rfc-editor.org/rfc/rfc8259)
- [json.tool 命令行工具](https://docs.python.org/3/library/json.html#module-json.tool)

## 相关笔记

- [[JSON]] — JSON 格式的语法、应用场景与跨语言对比
- [[Pydantic]] — 基于类型注解的数据校验与序列化
- [[API]] — JSON 是 API 数据交换的核心格式
- [[../用 Python 搭建复杂项目]] — 在真实项目中使用 JSON
- [[存档序列化与版本迁移]] — 序列化数据随版本演进的处理思路
- [[JavaScript]] — 前端侧对应的 `JSON.parse` / `JSON.stringify`
