---
title: Python msvcrt 库
date: 2026-11-01
tags:
  - Python
  - msvcrt
  - Windows
  - TUI
  - 教程
aliases:
  - msvcrt
  - Python msvcrt
  - Windows 控制台输入
related:
  - "[[TUI 笔记]]"
  - "[[Python curses 库]]"
  - "[[Python 笔记]]"
---

# Python msvcrt 库

`msvcrt` 是 Python 标准库中**仅 Windows 可用**的模块，封装了 Microsoft Visual C Runtime 的控制台与底层文件能力。TUI 开发中最常用的是它的**无回显、无需回车的按键读取**：`kbhit()` 判断是否有按键，`getwch()` 读取一个宽字符。

在 Windows 上没有 `curses` 时，`msvcrt` 常被用来实现方向键、快捷键和实时按键循环；跨平台项目通常会为它准备一个 Unix 的 `termios` / `curses` 分支。

## 核心要点

- **仅 Windows**：其它平台 `import msvcrt` 会 `ImportError`。
- `getch()` 返回 `bytes`，`getwch()` 返回 `str`；处理中文、Unicode 用 `getwch()`。
- 两者都**不回显、不需要回车**，直接从控制台读取。
- 方向键、功能键等特殊键会先返回 `\x00` 或 `\xe0`，需要再读一次拿到扫描码。
- `kbhit()` 用于非阻塞轮询，配合 `time.sleep()` 或事件循环使用。
- 必须有真实控制台；在 IDLE、部分 IDE 的「运行」窗口、Jupyter 中可能不可用。
- 它只负责读键，不负责清屏、光标和颜色；这些要配合 ANSI 转义序列或 Win32 API。

## 安装与平台

`msvcrt` 是 Windows 版 Python 自带的扩展模块，无需安装：

```python
import msvcrt          # 仅 Windows 可用
```

跨平台写法：

```python
try:
    import msvcrt
except ImportError:
    msvcrt = None
```

| 平台 | 按键读取方案 |
| --- | --- |
| Windows | `msvcrt.getwch()` + `kbhit()` |
| Linux / macOS | `termios` + `tty` + `select`，或 `curses`、`prompt_toolkit` |

## 常用函数

| 函数                                     | 作用                        |
| -------------------------------------- | ------------------------- |
| `msvcrt.getch()`                       | 阻塞读取一个按键，返回 `bytes`，不回显   |
| `msvcrt.getwch()`                      | 同 `getch()`，返回 `str`（宽字符） |
| `msvcrt.getche()`                      | 读取并回显，返回 `bytes`          |
| `msvcrt.getwche()`                     | 读取并回显，返回 `str`            |
| `msvcrt.kbhit()`                       | 是否有按键等待，返回 `bool`         |
| `msvcrt.ungetch(ch)`                   | 把一个字节退回输入缓冲区              |
| `msvcrt.ungetwch(ch)`                  | 把一个宽字符退回输入缓冲区             |
| `msvcrt.putch(ch)`                     | 向控制台写一个字节，不缓冲             |
| `msvcrt.putwch(ch)`                    | 向控制台写一个宽字符                |
| `msvcrt.setmode(fd, flags)`            | 设置文件描述符的文本/二进制模式          |
| `msvcrt.get_osfhandle(fd)`             | 由文件描述符取得 Windows 句柄       |
| `msvcrt.open_osfhandle(handle, flags)` | 把 Windows 句柄包装成文件描述符      |
| `msvcrt.locking(fd, mode, nbytes)`     | 文件区域加锁/解锁                 |
| `msvcrt.heapmin()`                     | 释放堆中未使用内存                 |

## 最小示例

```python
import msvcrt

print("按任意键继续...")
ch = msvcrt.getwch()
print(f"你按下了：{ch!r}")
```

- `getwch()` 会一直阻塞，直到有键按下。
- 不会在屏幕上回显，也不会等待回车。
- 返回的是单个字符字符串；方向键需要特殊处理（见下）。

## 非阻塞按键循环

`kbhit()` 让程序可以「有键就处理，没键就继续做别的事」：

```python
import msvcrt
import time

def read_key():
    """读取一个按键；没有按键时返回 None。"""
    if not msvcrt.kbhit():
        return None

    ch = msvcrt.getwch()
    if ch in ("\x00", "\xe0"):
        # 特殊键：再读一个扫描码
        return ch + msvcrt.getwch()
    return ch

while True:
    key = read_key()
    if key is not None:
        print(f"按键：{key!r}")
        if key in ("q", "Q", "\x1b"):   # q 或 Esc 退出
            break
    time.sleep(0.01)                     # 避免空转占满 CPU
```

要点：

- `kbhit()` 为 `True` 时，特殊键的第一个字符已经在缓冲区里。
- `sleep(0.01)` 既降低 CPU 占用，又保证响应足够快。
- 在真正的 TUI 里，把 `read_key()` 放进渲染循环即可。

## 特殊键与扫描码

`getwch()` 遇到方向键、功能键时，第一次返回 `'\x00'` 或 `'\xe0'`，第二次才返回扫描码。常见映射：

| 按键 | `getwch()` 返回 |
| --- | --- |
| 上 | `'\xe0H'` |
| 下 | `'\xe0P'` |
| 左 | `'\xe0K'` |
| 右 | `'\xe0M'` |
| Home | `'\xe0G'` |
| End | `'\xe0O'` |
| PageUp | `'\xe0I'` |
| PageDown | `'\xe0Q'` |
| Insert | `'\xe0R'` |
| Delete | `'\xe0S'` |
| F1 | `'\x00;'` |
| F2 | `'\x00<'` |
| F3 | `'\x00='` |
| F4 | `'\x00>'` |
| F5 | `'\x00?'` |
| F6 | `'\x00@'` |
| F7 | `'\x00A'` |
| F8 | `'\x00B'` |
| F9 | `'\x00C'` |
| F10 | `'\x00D'` |

普通键与组合键：

| 按键 | 返回值 |
| --- | --- |
| 字母 / 数字 | `'a'` / `'1'` |
| 回车 | `'\r'`（`\x0d`） |
| 退格 | `'\x08'` |
| Tab | `'\t'` |
| Esc | `'\x1b'` |
| Ctrl+A ~ Ctrl+Z | `'\x01'` ~ `'\x1a'` |
| Ctrl+C | `'\x03'` |
| 空格 | `' '` |

注意：

- `Enter` 在 `getwch()` 中是 `'\r'`，不是 `'\n'`。
- `F11` / `F12` 常被终端或系统拦截，不一定能读到。
- 不同终端/键盘布局的扫描码可能略有差异，建议先打印 `repr(key)` 实测。

## 按键名转换

把扫描码转成可读名称，便于写 TUI 逻辑：

```python
import msvcrt

SPECIAL = {
    "\xe0H": "UP",
    "\xe0P": "DOWN",
    "\xe0K": "LEFT",
    "\xe0M": "RIGHT",
    "\xe0G": "HOME",
    "\xe0O": "END",
    "\xe0I": "PGUP",
    "\xe0Q": "PGDN",
    "\xe0R": "INSERT",
    "\xe0S": "DELETE",
    "\x00;": "F1",
    "\x00<": "F2",
    "\x00=": "F3",
    "\x00>": "F4",
    "\x00?": "F5",
    "\x00@": "F6",
    "\x00A": "F7",
    "\x00B": "F8",
    "\x00C": "F9",
    "\x00D": "F10",
}

def get_key_name() -> str | None:
    if not msvcrt.kbhit():
        return None

    ch = msvcrt.getwch()
    if ch in ("\x00", "\xe0"):
        code = ch + msvcrt.getwch()
        return SPECIAL.get(code, f"UNKNOWN:{code!r}")

    if ch == "\r":
        return "ENTER"
    if ch == "\x08":
        return "BACKSPACE"
    if ch == "\x1b":
        return "ESC"
    if ch == "\t":
        return "TAB"
    return ch
```

## 与 ANSI 转义序列配合

`msvcrt` 只解决输入，输出侧可以用 ANSI 转义序列清屏、定位光标：

```python
import msvcrt
import shutil

def term_size() -> tuple[int, int]:
    size = shutil.get_terminal_size()
    return max(2, size.columns), max(2, size.lines)

def clear_screen() -> None:
    print("\033[2J\033[H", end="", flush=True)

def move_to(row: int, col: int) -> None:
    print(f"\033[{row};{col}H", end="", flush=True)

clear_screen()
move_to(1, 1)
print("按方向键移动，q 退出")

row = col = 5
while True:
    if msvcrt.kbhit():
        key = msvcrt.getwch()
        if key in ("\x00", "\xe0"):
            key += msvcrt.getwch()

        if key == "q":
            break
        elif key == "\xe0H":
            row = max(1, row - 1)
        elif key == "\xe0P":
            row += 1
        elif key == "\xe0K":
            col = max(1, col - 1)
        elif key == "\xe0M":
            col += 1

        clear_screen()
        move_to(row, col)
        print("@", end="", flush=True)

print("\n已退出")
```

Windows 10 及以上、Windows Terminal / 新版 `cmd` 默认支持 ANSI；老系统可能需要先启用虚拟终端处理，或改用 `colorama`。

## 编码与宽字符

- `getch()` / `putch()` 面向**字节**，不适合直接处理中文。
- `getwch()` / `putwch()` 面向**宽字符**，返回/接收 `str`。
- 读取中文输入时用 `getwch()`；但输入法（IME）组合过程不会经过它，无法做候选词界面。

```python
import msvcrt

print("请输入一个字符：", end="", flush=True)
ch = msvcrt.getwch()
print(f"\n收到：{ch}  U+{ord(ch):04X}")
```

## 文件与底层句柄

这些接口不常用于 TUI，但属于 `msvcrt` 的一部分。

### `setmode()`：文本 / 二进制模式

```python
import msvcrt
import os
import sys

# 关闭 Windows 的换行转换（\n -> \r\n）
msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)
```

常用于向标准输出写二进制数据（图片、协议包）时避免内容被改写。

### `get_osfhandle()` / `open_osfhandle()`

```python
import msvcrt
import os
import sys

handle = msvcrt.get_osfhandle(sys.stdout.fileno())
fd = msvcrt.open_osfhandle(handle, os.O_WRONLY)
```

用于和 Win32 API、`ctypes`、第三方库之间传递文件句柄。

### `locking()`：文件区域锁

```python
import msvcrt

with open("data.bin", "r+b") as f:
    fd = f.fileno()
    msvcrt.locking(fd, msvcrt.LK_LOCK, 10)    # 锁住从当前位置起的 10 字节
    try:
        ...
    finally:
        msvcrt.locking(fd, msvcrt.LK_UNLCK, 10)
```

常用模式：`LK_LOCK`（阻塞重试）、`LK_NBLCK`（非阻塞）、`LK_NBRLCK`（非阻塞读锁）、`LK_RLCK`（读锁）、`LK_UNLCK`（解锁）。

## 常见问题

1. **`ImportError: No module named 'msvcrt'`**：当前不是 Windows，需换用 `termios` / `curses`。
2. **按键没反应**：`getwch()` 会阻塞，确认程序真的执行到了读取；TUI 循环里应先用 `kbhit()` 判断。
3. **方向键只读到 `\x00` / `\xe0`**：忘记再调用一次 `getwch()` 读取扫描码。
4. **在 IDLE / Jupyter 中无效**：这些环境没有真实控制台，`msvcrt` 的读取行为不可靠，请在终端里运行。
5. **回车读出 `'\r'`**：不要只判断 `'\n'`。
6. **中文乱码或读不到**：用 `getwch()` 而不是 `getch()`，并确保终端编码为 UTF-8。
7. **Ctrl+C 不触发 `KeyboardInterrupt`**：`getwch()` 会把 `\x03` 当普通按键返回，需要自己处理退出。
8. **轮询占满 CPU**：`while True` 里加 `time.sleep(0.01)` 或改用事件驱动。
9. **ANSI 不生效**：老版本 Windows 控制台需启用 VT 处理，或使用 `colorama`。
10. **特殊键在不同终端不一致**：先 `print(repr(key))` 实测，再做映射。

## 与其它方案对比

| 方案 | 平台 | 特点 |
| --- | --- | --- |
| `msvcrt` | Windows | 标准库、无依赖、无回显读键，需自己处理扫描码 |
| `curses` | Unix（Windows 需 `windows-curses`） | 完整终端控制，按键常量统一 |
| `termios` + `tty` + `select` | Unix | 底层、灵活，需手动处理终端模式 |
| `prompt_toolkit` | 跨平台 | 输入编辑、补全、快捷键，抽象层级高 |
| `keyboard`（第三方） | 跨平台 | 全局热键，可监听系统级按键，需管理员权限的场景较多 |

更多 TUI 方案见 [[TUI 笔记]]。
