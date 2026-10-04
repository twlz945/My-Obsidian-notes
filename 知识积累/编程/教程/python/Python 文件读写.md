---
title: Python 文件读写
date: 2026-10-03
tags:
  - Python
  - 教程
  - 编程
aliases:
  - Python 文件 IO
  - Python open
  - Python 文件操作
related:
  - "[[python/python库/Python json 库]]"
  - "[[JSON]]"
  - "[[python/用 Python 搭建复杂项目]]"
  - "[[python/Python 网络编程教程]]"
---

# Python 文件读写

Python 通过内置函数 `open()` 打开文件，得到文件对象（file object），再用 `read` / `write` 等方法读写内容。核心是记住两点：**用 `with` 管理生命周期**，以及**显式声明 `encoding="utf-8"`**。若要在文件里存取结构化数据，见 [[python/python库/Python json 库]]。

## 核心要点

- 统一用 `with open(...) as f:`，异常时也能自动关闭文件。
- 文本模式读写的 `encoding` 要显式指定，Windows 默认编码（GBK）会导致中文乱码。
- 打开模式由 `r/w/a/x` + `b/t/+` 组合而成，`w` 会清空原文件，慎用。
- 读文本优先用 `for line in f` 逐行迭代，别对超大文件用 `read()`。
- 新项目优先用标准库 `pathlib`，比 `os.path` 拼接字符串更清晰。

## open() 基础

```python
open(file, mode="r", buffering=-1, encoding=None, errors=None, newline=None)

# 推荐写法：文本模式 + 显式编码
with open("data.txt", "r", encoding="utf-8") as f:
    text = f.read()

# 写入
with open("out.txt", "w", encoding="utf-8") as f:
    f.write("你好，世界\n")
```

- `file`：相对路径、绝对路径，或一个文件描述符 / `pathlib.Path` 对象。
- `mode`：打开模式，见下表。
- `encoding`：**仅文本模式可用**；二进制模式不要传。
- `newline`：文本模式下控制换行转换，跨平台处理 `\r\n` 时很重要（见下文）。
- `buffering`：缓冲策略，一般用默认值；行缓冲常用 `buffering=1`（配合交互/日志）。

## 打开模式

| 模式 | 含义 | 文件不存在 | 是否清空 |
| ---- | ---- | ---------- | -------- |
| `r` | 只读（默认） | 报 `FileNotFoundError` | 否 |
| `w` | 只写 | 新建 | **是** |
| `a` | 追加写 | 新建 | 否 |
| `x` | 独占创建 | 新建 | 否，已存在则报 `FileExistsError` |
| `r+` | 读写 | 报错 | 否 |
| `w+` | 读写 | 新建 | 是 |
| `a+` | 读写（写总在末尾） | 新建 | 否 |
| `rb` / `wb` / `ab` | 二进制模式 | 同上 | 同上 |

> [!warning] `w` 是危险模式
> 只要打开成功就会立刻清空文件，即使后面一个字节都没写。想防止误覆盖，用 `x` 先探测，或写临时文件再原子替换。

## with 上下文管理器

```python
# 推荐：离开 with 块时自动 close()，即使抛出异常
with open("data.txt", encoding="utf-8") as f:
    content = f.read()

# 需要同时操作多个文件时
with open("a.txt", encoding="utf-8") as src, open("b.txt", "w", encoding="utf-8") as dst:
    dst.write(src.read())
```

不要在 `with` 块外使用已关闭的文件对象。`f.closed` 可判断状态；也可手动 `f.close()`，但异常路径容易漏掉，因此不如 `with`。

## 读取方式

```python
with open("data.txt", encoding="utf-8") as f:
    text = f.read()            # 一次性读全部，返回 str
    chunk = f.read(1024)       # 读指定字符数（二进制模式为字节数）
    line = f.readline()        # 读一行（含结尾换行符）
    lines = f.readlines()      # 全部行，返回 list[str]

# 逐行迭代：大文件首选，内存友好
with open("data.txt", encoding="utf-8") as f:
    for line in f:
        print(line.rstrip("\n"))
```

| 方法 | 返回 | 适用场景 |
| ---- | ---- | -------- |
| `read()` | `str` / `bytes` | 小文件一次性读取 |
| `read(n)` | 片段 | 分块处理、二进制流 |
| `readline()` | 一行 | 逐行控制 |
| `readlines()` | `list` | 行不多、需要列表 |
| `for line in f` | 迭代器 | 大文件逐行处理（推荐） |

> [!tip] 去掉行尾换行
> `line.rstrip("\n")` 去掉行尾换行；Windows 文件可能是 `\r\n`，用 `rstrip("\r\n")` 或 `line.strip()`（后者会连行首空格一起去掉）。

## 写入方式

```python
with open("out.txt", "w", encoding="utf-8") as f:
    f.write("第一行\n")          # 不会自动加换行，需自己写 "\n"
    f.writelines(["a\n", "b\n"]) # 逐个写入，不补分隔符

# 追加
with open("out.txt", "a", encoding="utf-8") as f:
    f.write("追一行\n")

# 用 print 写文件
with open("out.txt", "w", encoding="utf-8") as f:
    print("hello", file=f)
```

- `write()` 返回写入的字符数（二进制模式为字节数）。
- `writelines()` 不会自动插入换行，需保证每个元素自带结尾。
- 高频小量写入可加缓冲（默认已缓冲）；对日志等需要即时可见的场景，配合 `flush()`。

## 文本模式与二进制模式

| 维度 | 文本模式（`t`，默认） | 二进制模式（`b`） |
| ---- | -------------------- | ----------------- |
| 读写类型 | `str` | `bytes` |
| 编码转换 | 自动（需 `encoding`） | 不转换 |
| 换行转换 | 会做（受 `newline` 控制） | 不做 |
| 典型用途 | 文本、CSV、JSON | 图片、音频、压缩包 |

```python
# 二进制：读写原始字节，不做编码/换行转换
with open("logo.png", "rb") as f:
    raw = f.read()

with open("copy.png", "wb") as f:
    f.write(raw)
```

> [!warning] 二进制模式不能传 `encoding`
> `open("x", "rb", encoding="utf-8")` 会抛 `ValueError`。同理，文本模式拿到的永远是 `str`，不要用 `len()` 当作文件字节数。

## 编码（encoding）

- 文本模式**务必显式指定** `encoding="utf-8"`；不指定则用平台默认（Windows 常为 GBK/CP936），跨机器容易乱码。
- 读未知来源文件可用 `errors="replace"` 容忍非法字节，或 `errors="ignore"` 直接跳过：
  ```python
  with open("messy.txt", encoding="utf-8", errors="replace") as f:
      text = f.read()
  ```
- 写文件时可加 `errors="ignore"` 避免个别字符导致失败（一般不推荐，最好修复数据源）。
- `open()` 只负责字节与字符串的转换，**不会**自动识别编码；需要猜编码时用第三方库（如 `charset-normalizer`）。

## 文件指针：seek 与 tell

```python
with open("data.bin", "rb") as f:
    print(f.tell())        # 当前位置（字节偏移）
    f.seek(10)             # 移动到第 10 字节
    f.seek(-5, 2)          # 从文件末尾往前 5 字节
    head = f.read(4)
```

- `seek(offset, whence)`：`whence` 为 `0`（开头，默认）、`1`（当前位置）、`2`（末尾）。
- `tell()` 返回当前偏移；**文本模式下偏移不是简单的字符序号**，强烈建议二进制模式做精确 seek。
- `a` / `a+` 模式下写入位置总在末尾，`seek` 只影响读取位置。

## pathlib：更现代的写法

`pathlib` 用对象代替字符串路径，跨平台、可读性好；Python 3 项目推荐优先使用。

```python
from pathlib import Path

p = Path("data") / "out.txt"          # 用 / 拼接路径，自动适配分隔符
print(p.name, p.suffix, p.parent)

# 读写文本（内部就是 open + with，仍可显式指定 encoding）
p.write_text("你好\n", encoding="utf-8")
text = p.read_text(encoding="utf-8")

# 需要更多控制时，仍用 Path.open()
with p.open("a", encoding="utf-8") as f:
    f.write("追加\n")

# 常用检查与遍历
print(p.exists(), p.is_file(), p.is_dir())
for child in Path("data").iterdir():
    print(child)
for py in Path(".").rglob("*.py"):
    print(py)
```

> [!tip] `read_text` / `write_text` 也要写编码
> 新版本 Python 里这两个方法支持 `encoding` 参数（与 `open` 一致），老代码若不传则用默认编码，中文环境同样可能乱码。养成显式传入的习惯。

## 目录与文件管理（os / shutil）

```python
import os, shutil

os.path.exists("data")            # 是否存在
os.makedirs("a/b/c", exist_ok=True)  # 递归创建目录
os.rename("a.txt", "b.txt")       # 重命名/移动
os.remove("b.txt")                # 删除文件
os.rmdir("empty_dir")             # 删除空目录

shutil.copy("a.txt", "b.txt")        # 复制文件（含元数据用 copy2）
shutil.copytree("src", "dst")        # 递归复制目录
shutil.rmtree("dst")                 # 递归删除目录（危险）
shutil.move("a.txt", "sub/a.txt")    # 移动/重命名
```

> - 删除类操作不可恢复，生产代码建议先校验路径、加日志或走回收站。
> - 需要临时文件用标准库 `tempfile`（`TemporaryDirectory` / `NamedTemporaryFile`），避免手工拼路径。

## 常见格式读写

| 格式 | 推荐方式 | 备注 |
| ---- | -------- | ---- |
| 纯文本 | `open(..., encoding="utf-8")` | 本节内容 |
| JSON | `json.dump` / `json.load` | 详见 [[python/python库/Python json 库]] |
| CSV | 标准库 `csv.reader` / `csv.writer` | 用 `newline=""` 打开 |
| 二进制/图片 | `open(..., "rb")` | 不做编码转换 |
| 配置文件 | `configparser`、`tomllib`（3.11+） | 视格式而定 |

CSV 示例（注意 `newline=""`，否则 Windows 上可能多出空行）：

```python
import csv

with open("rows.csv", "w", encoding="utf-8", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["name", "age"])
    writer.writerow(["Alice", 28])

with open("rows.csv", encoding="utf-8", newline="") as f:
    for row in csv.reader(f):
        print(row)
```

## 换行符（newline）

`newline` 参数决定换行的处理方式：

- 读模式：`None`（默认）会把 `\r\n`、`\r` 统一转换成 `\n`；`newline=""` 保留原样；其他值只按该字符分割行。
- 写模式：`None` 会把 `\n` 按平台转换成 `os.linesep`（Windows 上是 `\r\n`）；`newline=""` 或 `"\n"` 则不转换。

> [!tip] 固定用 `\n`
> 需要生成跨平台一致的文件（如给程序读的配置、CSV）时，写模式用 `newline="\n"`，避免在 Windows 上被写成 `\r\n`。

## 异常处理

```python
from pathlib import Path

try:
    with open("data.txt", encoding="utf-8") as f:
        data = f.read()
except FileNotFoundError:
    print("文件不存在")
except IsADirectoryError:
    print("目标是目录，不是文件")
except PermissionError:
    print("没有权限")
except UnicodeDecodeError:
    print("编码不对，考虑指定其它 encoding 或 errors='replace'")
except OSError as e:          # 以上都是 OSError 的子类
    print("系统级错误:", e)
```

| 异常 | 触发场景 |
| ---- | -------- |
| `FileNotFoundError` | 文件/目录不存在（`r`/`r+`） |
| `PermissionError` | 无读写权限、文件被占用 |
| `IsADirectoryError` | 把目录当文件打开 |
| `FileExistsError` | 用 `x` 模式但文件已存在 |
| `UnicodeDecodeError` | 解码失败（编码不匹配） |
| `UnicodeEncodeError` | 编码失败（内容含目标编码不支持的字符） |

## 大文件与性能

- **不要**对 GB 级文件用 `read()` / `readlines()`，会占满内存。
- 逐行处理或分块读取：
  ```python
  with open("big.log", encoding="utf-8") as f:
      while chunk := f.read(8192):   # 分块读取
          process(chunk)
  ```
- 二进制大文件同理，用固定 `read(n)` 循环。
- 写入大量内容时，先用 `io.StringIO` 在内存拼装、再一次性 `write`，通常比多次小 `write` 快。
- 处理完一次性小文件后，能复用文件对象就别反复开关；但跨函数传递文件对象会降低可读性，量级不大时优先清晰。

## 常见陷阱

1. **忘记 `encoding`**：Windows 默认 GBK，读 UTF-8 中文报 `UnicodeDecodeError` 或乱码。
2. **`w` 清空文件**：想追加却用了 `w`，原内容被抹掉。
3. **`write` 不自动换行**：连续 `write("a")` `write("b")` 得到 `ab`。
4. **二进制模式下用字符串**：`write("文本")` 报 `TypeError`，应传 `bytes`。
5. **文本模式传 `encoding` 给 `rb`**：抛 `ValueError`。
6. **文件没关**：不用 `with` 且异常中断，缓冲区未刷盘，甚至句柄泄漏。
7. **CSV 在 Windows 上多空行**：打开 CSV 文件没设 `newline=""`。
8. **在 `with` 外访问文件对象**：`ValueError: I/O operation on closed file`。
9. **路径用字符串硬拼**：漏掉分隔符或跨平台出错，改用 `pathlib` / `os.path.join`。

## 最佳实践

- 一律 `with`；一律显式 `encoding="utf-8"`。
- 写文件优先「写临时文件 → 校验 → 原子替换」，避免中途失败留下半截文件。
- 读未知文本先小量探测编码，或对可容忍场景用 `errors="replace"`。
- 结构化数据不要手工拼接文本，直接上 [[python/python库/Python json 库]]、`csv`、`configparser` 等。
- 用 `pathlib` 组织路径，用 `tempfile` 管理临时文件，用 `logging` 而非裸 `print` 写日志。
- 删除/覆盖操作前先确认路径，必要时做备份或 dry-run。

## 参考来源

- [open() — Python 官方文档](https://docs.python.org/3/library/functions.html#open)
- [io — Core tools for working with streams](https://docs.python.org/3/library/io.html)
- [pathlib — Object-oriented filesystem paths](https://docs.python.org/3/library/pathlib.html)
- [os — Miscellaneous operating system interfaces](https://docs.python.org/3/library/os.html)
- [shutil — High-level file operations](https://docs.python.org/3/library/shutil.html)

## 相关笔记

- [[python/python库/Python json 库]] — 用文件读写存取 JSON 数据
- [[JSON]] — JSON 格式本身与跨语言对比
- [[python/用 Python 搭建复杂项目]] — 文件读写在实际项目中的组织方式
- [[python/Python 网络编程教程]] — Python 标准库中的 IO 与网络读写对比
- [[存档序列化与版本迁移]] — 文件格式随版本演进的处理思路
