---
title: Python 字符串
date: 2026-11-01
tags:
  - Python
  - 字符串
  - 教程
aliases:
  - Python str
  - Python 字符串操作
  - 字符串
related:
  - "[[python/Python 文件读写]]"
  - "[[python/python库/Python json 库]]"
  - "[[python/Python进阶阶段学习规划表]]"
---

# Python 字符串

Python 的字符串类型是 `str`，表示**不可变的 Unicode 字符序列**。所有文本处理——拼接、切片、查找、替换、格式化、编码——都围绕它展开。掌握 `str` 的常用方法和格式化语法，能覆盖日常开发中绝大多数文本需求。

## 核心要点

- `str` **不可变**：任何「修改」都会产生新字符串。
- `str` 存储的是 Unicode 码点，不是字节；与 `bytes` 之间用 `encode()` / `decode()` 转换。
- 拼接大量片段优先用 `"".join(...)`，不要在循环里反复 `+=`。
- 格式化优先用 **f-string**，可读性和性能都最好。
- `==` 比较内容，`is` 比较对象身份；字符串比较不要用 `is`。
- 切片越界不会报错，索引越界会抛 `IndexError`。
- `strip()` 去掉的是**字符集合**，不是前缀/后缀；去前后缀用 `removeprefix()` / `removesuffix()`（3.9+）。
- 中文等宽字符的 `len()` 是码点数，不等于终端显示宽度。

## 创建字符串

```python
s1 = 'hello'
s2 = "hello"
s3 = """多行
字符串"""
s4 = '''也可以用三个单引号'''

# 转义字符
print("第一行\n第二行")     # 换行
print("列1\t列2")           # 制表符
print("反斜杠：\\")         # 反斜杠
print("引号：\"")           # 双引号
print("\u4f60\u597d")       # 你好（Unicode 转义）

# 原始字符串：反斜杠不转义
path = r"C:\Users\name\data"
pattern = r"\d+"

# 相邻字面量自动拼接
s = "Py" "thon"             # "Python"
```

`str()` 把其它类型转成字符串，`repr()` 返回更适合调试的表示：

```python
str(123)        # '123'
repr("a\nb")    # "'a\\nb'"
```

## 索引与切片

```python
s = "Python"

s[0]        # 'P'
s[-1]       # 'n'
s[1:4]      # 'yth'     左闭右开
s[:3]       # 'Pyt'
s[3:]       # 'hon'
s[::2]      # 'Pto'
s[::-1]     # 'nohtyP'   反转
s[100:]     # ''        切片越界不报错
# s[100]    # IndexError
```

切片会创建新字符串；原字符串始终不变。

## 不可变性

```python
s = "abc"
# s[0] = "A"          # TypeError: 'str' object does not support item assignment

s = "A" + s[1:]        # 生成新字符串 "Abc"
```

因为不可变，字符串可以作为 `dict` 的键、放进 `set`，也天然线程安全。

## 常用方法速查

### 查找与判断

| 方法 | 说明 |
| --- | --- |
| `s.find(sub)` | 返回首次出现的索引，找不到返回 `-1` |
| `s.rfind(sub)` | 从右往左找，找不到返回 `-1` |
| `s.index(sub)` | 同 `find`，找不到抛 `ValueError` |
| `s.count(sub)` | 统计子串出现次数 |
| `s.startswith(prefix)` | 是否以某前缀开头，可传元组 |
| `s.endswith(suffix)` | 是否以某后缀结尾，可传元组 |
| `sub in s` | 是否包含子串 |
| `s.isalpha()` | 是否全为字母 |
| `s.isdigit()` | 是否全为数字字符 |
| `s.isalnum()` | 是否全为字母或数字 |
| `s.isspace()` | 是否全为空白 |
| `s.islower()` / `s.isupper()` | 是否全为小写 / 大写 |

```python
"hello.py".endswith((".py", ".pyw"))   # True
"abc".find("x")                        # -1
"abc".index("x")                       # ValueError
```

### 大小写

```python
"hello".upper()        # 'HELLO'
"HELLO".lower()        # 'hello'
"hello world".title()  # 'Hello World'
"hello".capitalize()   # 'Hello'
"Hello".swapcase()     # 'hELLO'
"Straße".casefold()    # 'strasse'  适合大小写无关比较
```

### 去除空白与字符

```python
"  hi  ".strip()          # 'hi'
"  hi  ".lstrip()         # 'hi  '
"  hi  ".rstrip()         # '  hi'
"xxhixx".strip("x")       # 'hi'
"###标题###".strip("#")   # '标题'
```

注意：`strip("ab")` 会去掉首尾所有 `a` 和 `b`，不是去掉子串 `"ab"`。

```python
"prefix-body".removeprefix("prefix-")   # 'body'   3.9+
"body-suffix".removesuffix("-suffix")   # 'body'
```

### 拆分与合并

```python
"a,b,c".split(",")          # ['a', 'b', 'c']
"a,b,c".rsplit(",", 1)      # ['a,b', 'c']
"a  b\t c\n".split()        # ['a', 'b', 'c']   按任意空白切分
"a b  c".split(" ")         # ['a', 'b', '', 'c']  保留空串
"a\nb\r\nc".splitlines()    # ['a', 'b', 'c']

"-".join(["a", "b", "c"])   # 'a-b-c'
"".join(["P", "y", "t"])    # 'Pyt'
```

`split()` 不带参数时会合并连续空白并忽略首尾空白；`split(" ")` 则会保留空字符串。

```python
"key=value".partition("=")   # ('key', '=', 'value')
"key=value".rpartition("=")  # ('key', '=', 'value')
```

`partition()` 返回三元组，找不到分隔符时返回 `(原串, "", "")`，适合安全拆分。

### 替换

```python
"a-b-c".replace("-", "_")        # 'a_b_c'
"a-b-c".replace("-", "_", 1)     # 'a_b-c'

table = str.maketrans({"a": "1", "b": "2"})
"abc".translate(table)           # '123'
```

`replace()` 默认替换全部匹配；正则替换用 `re.sub()`。

### 对齐与填充

```python
"hi".center(10, "-")   # '----hi----'
"hi".ljust(10, ".")    # 'hi........'
"hi".rjust(10, ".")    # '........hi'
"42".zfill(5)          # '00042'
```

## 格式化

### f-string（推荐）

```python
name, age = "Alice", 30

f"{name} is {age}"             # 'Alice is 30'
f"{age = }"                    # 'age = 30'   调试用
f"{3.14159:.2f}"               # '3.14'
f"{1234567:,}"                 # '1,234,567'
f"{42:08d}"                    # '00000042'
f"{'hi':>10}"                  # '        hi'
f"{'hi':*^10}"                 # '****hi****'
f"{0.25:.1%}"                  # '25.0%'
f"{255:#x}"                    # '0xff'
f"{value!r}"                   # 使用 repr()
```

日期格式化：

```python
from datetime import date
d = date(2026, 11, 1)
f"{d:%Y-%m-%d}"                # '2026-11-01'
```

常见格式说明符：

| 语法 | 含义 |
| --- | --- |
| `:.2f` | 保留 2 位小数 |
| `:,` | 千分位分隔 |
| `:08d` | 宽度 8，左侧补 0 |
| `:>10` / `:<10` / `:^10` | 右 / 左 / 居中对齐 |
| `:*^10` | 用 `*` 填充并居中 |
| `:.1%` | 百分比，保留 1 位小数 |
| `:#x` / `:#b` / `:#o` | 十六 / 二 / 八进制带前缀 |
| `!r` / `!s` | 转换用 `repr()` / `str()` |

### `str.format()`

```python
"{} is {}".format("Alice", 30)
"{name} is {age}".format(name="Alice", age=30)
"{0:.2f}".format(3.14159)
```

### `%` 格式化（旧式）

```python
"%s is %d" % ("Alice", 30)
"%.2f" % 3.14159
```

新代码不建议使用，维护旧代码时认识即可。

## 编码与字节

`str` 是文本，`bytes` 是字节序列，二者不能直接拼接：

```python
text = "你好"
data = text.encode("utf-8")     # b'\xe4\xbd\xa0\xe5\xa5\xbd'
back = data.decode("utf-8")     # '你好'

len(text)    # 2   字符数
len(data)    # 6   字节数
```

常见编码问题：

```python
b = b"\xff\xfe"
# b.decode("utf-8")            # UnicodeDecodeError

b.decode("utf-8", errors="ignore")   # 丢弃非法字节
b.decode("utf-8", errors="replace")  # 用 � 替换
```

- 文件读写显式写 `encoding="utf-8"`，见 [[python/Python 文件读写]]。
- 带 BOM 的 UTF-8 文件用 `encoding="utf-8-sig"` 读取。
- 网络传输、哈希、加密面向字节，需要先 `encode()`。

## 多行文本与 `textwrap`

```python
from textwrap import dedent, wrap, fill

text = dedent("""
    第一行
    第二行
""").strip()

print(text)          # 第一行\n第二行

wrap("a long sentence ...", width=20)   # 按宽度切成列表
fill("a long sentence ...", width=20)   # 切成一段文本
```

直接写三引号字符串时，缩进会原样保留；`dedent()` 可去掉公共缩进。

## Unicode 与中文

### 码点、长度与显示宽度

```python
s = "你好A"
len(s)          # 3   码点数
[hex(ord(c)) for c in s]   # ['0x4f60', '0x597d', '0x41']
```

中文在终端通常占 **2 列**，`len()` 只数码点，居中排版时要用 `wcwidth`：

```python
from wcwidth import wcswidth

wcswidth("你好")    # 4
wcswidth("abc")     # 3
```

### Unicode 规范化

同一个字符可能有不同码点组合，例如 `é` 可以是单码点，也可以是 `e` + 组合重音：

```python
import unicodedata

a = "é"                                  # U+00E9
b = "e\u0301"                            # e + U+0301
a == b                                   # False

unicodedata.normalize("NFC", a) == unicodedata.normalize("NFC", b)   # True
```

比较用户输入、文件名、搜索关键词时，先做 `NFC` 规范化更稳妥。

### 大小写无关比较

```python
"Straße".casefold() == "STRASSE".casefold()   # True
```

`lower()` 对某些语言不够，`casefold()` 更适合做忽略大小写的比较。

## 性能与最佳实践

1. **循环拼接用 `join`**：

   ```python
   # 差：每次 += 都可能创建新字符串
   result = ""
   for part in parts:
       result += part

   # 好
   result = "".join(parts)
   ```

2. **格式化优先 f-string**：通常比 `%` 和 `format()` 更快、更直观。
3. **判断前后缀用 `startswith` / `endswith`**，比切片再比较更清晰，也支持元组。
4. **大量重复键可用 `sys.intern()`** 减少内存，但不要滥用。
5. **`in` 是线性扫描**，超长文本的频繁查找考虑正则或专门的数据结构。
6. **正则处理复杂模式**：拆分、替换规则一多，`re` 比手写字符串方法更清晰。

## 常见陷阱

1. **`is` 不是 `==`**：短字符串可能被驻留（interning），但这是实现细节，不能依赖。
2. **`strip()` 不是去前缀**：去前缀用 `removeprefix()`，或用 `startswith()` 判断后切片。
3. **`split(" ")` 与 `split()` 不同**：前者保留空串，后者按任意空白合并。
4. **切片越界不报错**，索引越界才报 `IndexError`。
5. **字符串不可变**：`s[0] = "x"` 永远报错，要重新赋值。
6. **`len()` 不等于显示宽度**：中文、emoji 的终端宽度要用 `wcwidth`。
7. **Unicode 规范化问题**：看起来相同的字符可能不相等，比较前考虑 `NFC`。
8. **`str` 与 `bytes` 混用**：拼接、比较前先统一类型。
9. **f-string 嵌套引号**：3.12 之前同种引号不能嵌套，必要时用不同引号或提前赋值。
10. **`replace()` 默认全替换**：只想替换一次要传 `count`。
