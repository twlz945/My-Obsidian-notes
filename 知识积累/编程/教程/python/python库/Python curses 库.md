---
title: Python curses 库
date: 2026-11-01
tags:
  - Python
  - curses
  - TUI
  - 教程
aliases:
  - curses
  - Python curses
  - ncurses
related:
  - "[[TUI 笔记]]"
  - "[[Python 笔记]]"
  - "[[Python Textual 库]]"
  - "[[Python urwid 库]]"
---

# Python curses 库

`curses` 是 Python 标准库中用于**终端全屏字符界面**的模块，底层封装了 Unix 的 ncurses（Windows 上为 PDCurses）。它提供光标移动、窗口、颜色、键盘和鼠标事件等能力，是理解所有 TUI 框架底层原理的起点。

`curses` 抽象层级低：没有现成控件、没有样式表、没有事件框架，所有界面都要自己用坐标绘制。适合需要精细控制终端、或不想引入第三方依赖的场景；日常开发更推荐 [[Python Textual 库]] 或 [[Python urwid 库]]。

## 核心要点

- `curses.wrapper(func)` 负责初始化终端并在异常时恢复，**优先使用它**而不是手动 `initscr()` / `endwin()`。
- 终端是一块 `行 × 列` 的字符网格，坐标写作 `(y, x)`，左上角为 `(0, 0)`。
- 所有绘制先写入窗口缓冲区，调用 `refresh()` 后才显示到屏幕。
- `keypad(True)` 后 `getch()` 才会返回 `KEY_UP`、`KEY_RESIZE` 等特殊键常量。
- 颜色需 `start_color()` + `init_pair()` + `color_pair()` 三步配合。
- `addstr()` 写到右下角最后一个字符时可能抛 `curses.error`，需要捕获。
- Windows 默认没有 `curses`，需安装 `windows-curses`。
- 中文等宽字符占两列，`len()` 计算的宽度会偏小，居中/对齐时要用 `wcwidth` 修正。

## 安装与平台

| 平台 | 说明 |
| --- | --- |
| Linux / macOS | 标准库自带，无需安装 |
| Windows | `pip install windows-curses` |

```bash
pip install windows-curses   # 仅 Windows
```

Windows 上建议使用 Windows Terminal，传统 `cmd.exe` 对颜色和宽字符的支持较差。

## 最小示例

```python
import curses

def main(stdscr):
    curses.curs_set(0)        # 隐藏光标（部分终端可能抛错，可 try 包裹）
    stdscr.keypad(True)       # 启用方向键等特殊键

    while True:
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        msg = "Hello, curses! 按 q 退出"
        y, x = h // 2, max(0, (w - len(msg)) // 2)

        try:
            stdscr.addstr(y, x, msg)
        except curses.error:
            pass              # 写右下角可能越界

        stdscr.refresh()

        if stdscr.getch() in (ord("q"), ord("Q")):
            break

curses.wrapper(main)
```

`wrapper()` 会完成 `initscr()`、`noecho()`、`cbreak()`、`keypad(True)` 等初始化，并在函数返回或抛异常后恢复终端。

## 初始化与清理

`wrapper()` 等价于下面这套手动流程（了解即可，实际优先用 `wrapper`）：

```python
import curses

stdscr = curses.initscr()
try:
    curses.noecho()        # 不回显按键
    curses.cbreak()        # 按键立即生效，无需回车
    stdscr.keypad(True)    # 解析特殊键
    curses.curs_set(0)

    stdscr.addstr(0, 0, "按任意键退出")
    stdscr.refresh()
    stdscr.getch()
finally:
    stdscr.keypad(False)
    curses.nocbreak()
    curses.echo()
    curses.endwin()        # 恢复终端
```

若程序异常退出且没有执行 `endwin()`，终端可能停留在无回显、乱码状态；此时在 shell 中执行 `reset` 或 `stty sane` 恢复。

## 窗口与坐标

| 方法 | 作用 |
| --- | --- |
| `stdscr.getmaxyx()` | 返回 `(行数, 列数)` |
| `stdscr.move(y, x)` | 移动光标 |
| `stdscr.addstr(y, x, text[, attr])` | 在指定位置输出字符串 |
| `stdscr.addch(y, x, ch[, attr])` | 输出单个字符 |
| `stdscr.erase()` | 清空窗口缓冲区 |
| `stdscr.clear()` | 清空并强制整屏重绘 |
| `stdscr.refresh()` | 把缓冲区刷到屏幕 |
| `stdscr.hline(y, x, ch, n)` | 画水平线 |
| `stdscr.vline(y, x, ch, n)` | 画垂直线 |
| `stdscr.border()` | 画边框 |
| `stdscr.box()` | 给窗口画边框 |

窗口对象可嵌套创建：

```python
win = curses.newwin(height, width, begin_y, begin_x)
win.addstr(0, 0, "子窗口")
win.refresh()
```

## 输入与按键

```python
key = stdscr.getch()          # 返回 int；普通字符可用 chr(key)
key = stdscr.getkey()         # 返回 str，如 "a"、"KEY_UP"
key = stdscr.get_wch()        # 宽字符输入，返回 str 或 int
```

常用键常量：

| 常量 | 含义 |
| --- | --- |
| `curses.KEY_UP` / `KEY_DOWN` / `KEY_LEFT` / `KEY_RIGHT` | 方向键 |
| `curses.KEY_ENTER` | 回车（部分终端仍返回 `10` / `13`） |
| `curses.KEY_BACKSPACE` / `KEY_DC` | 退格 / Delete |
| `curses.KEY_HOME` / `KEY_END` | Home / End |
| `curses.KEY_RESIZE` | 终端尺寸变化 |
| `curses.KEY_MOUSE` | 鼠标事件 |
| `curses.KEY_F1` … `KEY_F12` | 功能键 |

非阻塞与超时：

```python
stdscr.nodelay(True)      # getch() 无输入时立即返回 -1
stdscr.timeout(500)       # 最多阻塞 500ms，超时返回 -1
```

## 颜色与属性

```python
import curses

def main(stdscr):
    if not curses.has_colors():
        return

    curses.start_color()
    curses.use_default_colors()   # 允许背景使用终端默认色（-1）
    curses.init_pair(1, curses.COLOR_CYAN, curses.COLOR_BLACK)
    curses.init_pair(2, curses.COLOR_YELLOW, curses.COLOR_BLUE)

    stdscr.addstr(0, 0, "青色加粗", curses.color_pair(1) | curses.A_BOLD)
    stdscr.addstr(1, 0, "黄底蓝字", curses.color_pair(2))
    stdscr.addstr(2, 0, "反色", curses.A_REVERSE)
    stdscr.refresh()
    stdscr.getch()

curses.wrapper(main)
```

常用属性：

| 属性 | 效果 |
| --- | --- |
| `A_NORMAL` | 正常 |
| `A_BOLD` | 加粗 / 高亮 |
| `A_REVERSE` | 前景背景反色 |
| `A_UNDERLINE` | 下划线 |
| `A_DIM` | 变暗 |
| `A_BLINK` | 闪烁（部分终端不支持） |

颜色相关常量：`COLOR_BLACK`、`COLOR_RED`、`COLOR_GREEN`、`COLOR_YELLOW`、`COLOR_BLUE`、`COLOR_MAGENTA`、`COLOR_CYAN`、`COLOR_WHITE`；可用颜色数与配色对数见 `curses.COLORS`、`curses.COLOR_PAIRS`。

## 窗口与 Pad

普通窗口受屏幕尺寸限制；**Pad** 可以是任意大的虚拟画布，通过 `refresh()` 指定显示哪一块：

```python
pad = curses.newpad(100, 200)     # 100 行 × 200 列
pad.addstr(50, 10, "Pad 中的内容")

# refresh(pad_top, pad_left, screen_top, screen_left, screen_bottom, screen_right)
pad.refresh(40, 0, 2, 2, 20, 78)
```

这适合实现滚动日志、大表格等超出屏幕的内容。

## 菜单示例

```python
import curses

def main(stdscr):
    curses.curs_set(0)
    stdscr.keypad(True)

    items = ["新建", "打开", "退出"]
    index = 0

    while True:
        stdscr.erase()
        for i, item in enumerate(items):
            attr = curses.A_REVERSE if i == index else curses.A_NORMAL
            stdscr.addstr(2 + i, 4, item, attr)
        stdscr.refresh()

        key = stdscr.getch()
        if key in (curses.KEY_UP, ord("k")):
            index = (index - 1) % len(items)
        elif key in (curses.KEY_DOWN, ord("j")):
            index = (index + 1) % len(items)
        elif key in (10, 13, curses.KEY_ENTER):
            if items[index] == "退出":
                break

curses.wrapper(main)
```

## 文本输入

标准库提供了 `curses.textpad.Textbox`，可快速实现单行/多行编辑框：

```python
import curses
import curses.textpad

def main(stdscr):
    stdscr.erase()
    stdscr.addstr(0, 0, "输入内容（Ctrl-G 结束）：")

    win = curses.newwin(1, 40, 1, 0)
    box = curses.textpad.Textbox(win)
    text = box.edit()

    stdscr.addstr(3, 0, f"你输入了：{text.strip()}")
    stdscr.refresh()
    stdscr.getch()

curses.wrapper(main)
```

更复杂的输入需要自己维护缓冲区、光标位置和按键处理。

## 鼠标与尺寸变化

启用鼠标：

```python
curses.mousemask(curses.ALL_MOUSE_EVENTS)

key = stdscr.getch()
if key == curses.KEY_MOUSE:
    _, mx, my, _, bstate = curses.getmouse()
    if bstate & curses.BUTTON1_CLICKED:
        stdscr.addstr(0, 0, f"点击了 ({my}, {mx})")
```

处理终端缩放：

```python
if key == curses.KEY_RESIZE:
    h, w = stdscr.getmaxyx()
    # 重新计算布局
```

并非所有终端都会发送鼠标和 resize 事件，代码中要做好降级。

## Unicode 与中文

- `addstr()` 可以直接接收 `str`，但终端能否正确显示取决于 locale 与字体。
- 中文、日文等**全角字符占两列**，`len("中文") == 2` 但显示宽度为 4。
- 居中、截断、光标定位时应使用 `wcwidth` 计算显示宽度：

```python
from wcwidth import wcswidth

def center_x(width: int, text: str) -> int:
    return max(0, (width - wcswidth(text)) // 2)
```

- 输入宽字符用 `get_wch()`；`getch()` 返回的是字节/键码，不适合直接当字符处理。

## 调试与注意事项

1. **不要用 `print()` 调试**：会破坏 curses 画面，日志请写入文件。
2. **优先 `curses.wrapper()`**：保证异常时终端能恢复。
3. **写右下角要捕获 `curses.error`**：最后一个单元格写入会越界。
4. **记得 `refresh()`**：只改缓冲区不会显示。
5. **`keypad(True)` 不能漏**：否则方向键会变成 `ESC` 序列。
6. **`curs_set()` 可能失败**：部分终端不支持隐藏光标，用 `try/except curses.error` 包裹。
7. **全量重绘会闪烁**：尽量只更新变化的区域，或使用 `erase()` + 局部绘制。
8. **Windows 兼容性有限**：`windows-curses` 可用，但颜色、鼠标、宽字符支持不如 Unix。
9. **终端状态异常**：程序崩溃后执行 `reset` / `stty sane` 恢复。

## 与其它 TUI 库对比

| 维度 | curses | Textual | urwid | prompt_toolkit |
| --- | --- | --- | --- | --- |
| 抽象层级 | 低（字符网格） | 高（组件 + CSS） | 中（控件 + 容器） | 中（输入/布局） |
| 是否标准库 | 是 | 否 | 否 | 否 |
| 样式能力 | 手写属性 | 强（TCSS） | 中（palette） | 有限 |
| 异步支持 | 无 | 原生 | 可接入 asyncio | 部分 |
| 学习曲线 | 陡 | 中 | 中 | 中 |
| 适合场景 | 底层控制、学习原理 | 现代终端应用 | 传统控件界面 | 交互式命令行 |

更多 TUI 方案见 [[TUI 笔记]]。
