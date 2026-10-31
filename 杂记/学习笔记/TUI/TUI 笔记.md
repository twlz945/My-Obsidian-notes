---
date: 2026-10-31
related:
  - "[[Python 笔记]]"
  - "[[Python Textual 库]]"
  - "[[Python urwid 库]]"
tags:
  - python
  - tui
---
# 全屏终端界面（TUI）

TUI（Text User Interface）是在终端里用字符绘制的全屏交互界面，支持布局、键盘/鼠标事件、颜色和实时刷新。

## 常见库对比

| 库                | 定位            | 优点                      | 局限                                 |
| ---------------- | ------------- | ----------------------- | ---------------------------------- |
| `curses`         | 标准库、底层终端控制    | 无第三方依赖、性能好              | API 原始；Windows 需装 `windows-curses` |
| `textual`        | 现代 TUI 框架     | CSS 样式、组件化、异步、鼠标、跨平台    | 依赖较多、学习曲线略陡                        |
| `prompt_toolkit` | 交互式命令行 / 全屏应用 | 输入编辑、补全、历史、快捷键强         | 更偏交互式输入，界面组件不如 Textual 丰富          |
| `urwid`          | 老牌控件库         | 控件成熟、文档多                | API 较旧、样式能力有限                      |
| `blessed`        | 终端能力封装        | 易上手、跨平台、颜色/光标 API 友好    | 不是完整应用框架                           |
| `rich`           | 富文本渲染         | 表格、进度条、语法高亮、Markdown 漂亮 | 不是全屏 TUI 框架                        |

安装：

```bash
pip install textual
pip install prompt_toolkit
pip install urwid blessed rich
pip install windows-curses   # 仅 Windows 用 curses 时
```

## `curses` 最小示例

```python
import curses

def main(stdscr):
    curses.curs_set(0)                 # 隐藏光标
    stdscr.clear()
    h, w = stdscr.getmaxyx()           # 终端行数、列数
    msg = "Hello, TUI! 按 q 退出"
    stdscr.addstr(h // 2, (w - len(msg)) // 2, msg)
    stdscr.refresh()

    while True:
        if stdscr.getch() == ord("q"):
            break

curses.wrapper(main)                   # 自动初始化/恢复终端
```

要点：

- 终端是 `行 × 列` 的字符网格，坐标写作 `(y, x)`。
- `refresh()` 把缓冲区内容刷到屏幕，频繁全量重绘会闪烁。
- `curses.wrapper()` 负责异常时恢复终端状态，避免终端「坏掉」。

## `textual` 最小示例

```python
from textual.app import App, ComposeResult
from textual.widgets import Footer, Header, Static

class MyApp(App):
    BINDINGS = [("q", "quit", "退出")]

    def compose(self) -> ComposeResult:
        yield Header()
        yield Static("Hello, Textual!", id="hello")
        yield Footer()

if __name__ == "__main__":
    MyApp().run()
```

运行：

```bash
python app.py
textual run --dev app.py   # 开发模式，支持热重载和调试控制台
```

Textual 用 `compose()` 声明组件树，布局和样式可用类似 CSS 的语法写在 `CSS` 变量或 `.tcss` 文件里；事件通过 `on_<event>` 方法或消息机制处理。

完整用法见 [[Python Textual 库]]。

## `prompt_toolkit` 全屏示例

```python
from prompt_toolkit import Application
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.layout import Layout
from prompt_toolkit.widgets import Frame, TextArea

kb = KeyBindings()

@kb.add("c-q")
def quit_app(event):
    event.app.exit()

body = TextArea(text="全屏编辑器\n按 Ctrl-Q 退出")
app = Application(
    layout=Layout(Frame(body)),
    key_bindings=kb,
    full_screen=True,
)
app.run()
```

## `urwid` 最小示例

```python
import urwid

def exit_on_q(key):
    if key in ("q", "Q"):
        raise urwid.ExitMainLoop()

text = urwid.Text("Hello, urwid! 按 q 退出", align="center")
loop = urwid.MainLoop(urwid.Filler(text, "middle"), unhandled_input=exit_on_q)
loop.run()
```

完整用法见 [[Python urwid 库]]。

## 核心概念

- **字符网格**：界面由行列坐标上的字符和样式组成。
- **ANSI 转义序列**：控制光标位置、颜色、清屏等，TUI 库底层都会生成这些序列。详见 [[ANSI 转义序列]]。
- **事件循环**：持续读取按键/鼠标事件并重绘，程序通常阻塞在 `run()` / `getch()`。
- **双缓冲与局部刷新**：先在内存里画好一帧，再只更新变化的区域，减少闪烁。
- **尺寸变化**：监听 resize 事件（`curses` 的 `KEY_RESIZE`、Textual 的 `on_resize`）重新布局。
- **颜色**：支持 16 色、256 色和真彩色（truecolor），具体取决于终端。
- **鼠标**：多数库需显式开启鼠标支持，且并非所有终端都兼容。

## 选择建议

- **想要现代、组件化、带样式的应用** → `textual`
- **重点是输入编辑、补全、快捷键** → `prompt_toolkit`
- **Unix 环境、追求零依赖、控制细粒度** → `curses`
- **需要成熟传统控件（列表、表单、对话框）** → `urwid`
- **只想让终端输出更漂亮，不需要全屏交互** → `rich`
