---
title: Python urwid 库
date: 2026-10-31
tags:
  - Python
  - urwid
  - TUI
  - 教程
aliases:
  - urwid
  - Python urwid
related:
  - "[[../../../../../杂记/学习笔记/TUI/TUI 笔记]]"
  - "[[Python 笔记]]"
  - "[[Python Textual 库]]"
---

# Python urwid 库

[urwid](https://urwid.org/) 是 Python 的老牌 TUI（Text User Interface）库，提供一套完整的控件、布局容器和事件循环，用纯 Python 编写。它的设计思路接近传统 GUI 工具包：**控件树 + 容器布局 + 信号回调**，适合开发终端菜单、表单、列表、文件管理器等交互界面。

与 [[Python Textual 库]] 相比，urwid 更早、更轻量，API 偏传统，样式能力有限，但成熟稳定、依赖少，适合不想引入现代框架的场景。

## 核心要点

- 界面由**控件（Widget）**和**容器（Container）**组成，最外层交给 `MainLoop` 驱动。
- 布局容器：`Pile`（纵向）、`Columns`（横向）、`Filler`（填充剩余空间）、`Frame`（页眉/主体/页脚）、`Padding`（留白）。
- `ListBox` 需要配合 `ListWalker`（常用 `SimpleFocusListWalker`）提供可滚动列表。
- 交互用 `urwid.connect_signal(widget, "click" / "change", callback)` 绑定回调。
- 颜色通过 **palette** 定义，再用 `AttrMap` 应用到控件上。
- 退出通常抛 `urwid.ExitMainLoop()`；全局按键可用 `unhandled_input` 处理。
- 默认支持 16 色、256 色和真彩色（`#rrggbb`），具体取决于终端。

## 安装

```bash
pip install urwid
```

urwid 纯 Python 实现，无编译依赖。

## 最小应用

```python
import urwid

def on_exit(key):
    if key in ("q", "Q"):
        raise urwid.ExitMainLoop()

palette = [
    ("header", "white", "dark blue"),
    ("footer", "black", "light gray"),
    ("focus", "black", "light cyan"),
]

header = urwid.AttrMap(urwid.Text("Urwid Demo", align="center"), "header")
footer = urwid.AttrMap(urwid.Text("q 退出"), "footer")

items = [
    urwid.AttrMap(urwid.Text(f"第 {i} 项"), None, focus_map="focus")
    for i in range(1, 6)
]
body = urwid.ListBox(urwid.SimpleFocusListWalker(items))

frame = urwid.Frame(body, header=header, footer=footer)
urwid.MainLoop(frame, palette, unhandled_input=on_exit).run()
```

运行后可用方向键在列表中移动，按 `q` 退出。

## 核心概念

| 概念 | 说明 |
| --- | --- |
| `Widget` | 所有控件的基类，负责绘制与按键处理 |
| `WidgetWrap` | 包装其它控件并扩展行为，常用于自定义控件 |
| `Container` | 管理子控件的布局容器 |
| `ListWalker` | 为 `ListBox` 提供可迭代的控件集合与焦点位置 |
| `MainLoop` | 事件循环：读取输入、重绘、调度定时器 |
| `Canvas` | 控件渲染结果的字符网格，一般无需直接操作 |
| `Palette` | 颜色方案，`(名称, 前景, 背景[, 单色])` 的列表 |
| `AttrMap` | 把 palette 中的属性映射到控件，可指定 `focus_map` |

## 布局容器

### `Pile`：纵向堆叠

```python
pile = urwid.Pile([
    urwid.Text("顶部"),
    urwid.Divider(),
    urwid.Text("底部"),
])
```

### `Columns`：横向排列

```python
columns = urwid.Columns([
    ("weight", 1, urwid.Text("左侧")),
    ("weight", 2, urwid.Text("右侧")),
])
```

宽度可写固定字符数、`("weight", n, widget)` 或 `("fixed", n, widget)`。

### `Filler`：填满剩余空间

```python
body = urwid.Filler(urwid.Text("居中"), valign="middle")
```

`valign` 可选 `"top"` / `"middle"` / `"bottom"`。

### `Frame`：页眉 + 主体 + 页脚

```python
frame = urwid.Frame(
    body=urwid.Filler(urwid.Text("内容")),
    header=urwid.Text("标题"),
    footer=urwid.Text("状态栏"),
)
```

### `Padding`：留白

```python
padded = urwid.Padding(urwid.Text("带边距"), left=2, right=2)
```

## 常用控件

| 控件 | 用途 |
| --- | --- |
| `urwid.Text` | 静态文本，支持对齐与换行 |
| `urwid.Edit` | 单行输入框 |
| `urwid.Button` | 按钮 |
| `urwid.CheckBox` | 复选框 |
| `urwid.RadioButton` | 单选按钮（同组互斥） |
| `urwid.ListBox` | 可滚动列表 |
| `urwid.SimpleFocusListWalker` | 带焦点的列表数据源 |
| `urwid.Columns` / `Pile` | 横向 / 纵向布局 |
| `urwid.Filler` / `Padding` | 填充与留白 |
| `urwid.Frame` | 带页眉页脚的框架 |
| `urwid.AttrMap` | 应用调色板样式 |
| `urwid.Divider` | 分隔线 |
| `urwid.SolidFill` | 纯色填充块 |
| `urwid.ProgressBar` | 进度条 |
| `urwid.BigText` | 大号文字 |
| `urwid.BarGraph` | 柱状图 |

## 事件与信号

### 按钮

```python
def on_click(button):
    text.set_text(f"点击了 {button.label}")

button = urwid.Button("确定")
urwid.connect_signal(button, "click", on_click)
```

### 输入框

```python
edit = urwid.Edit("姓名：")

def on_change(widget, new_text):
    result.set_text(f"你好，{new_text}")

urwid.connect_signal(edit, "change", on_change)
```

### 复选 / 单选

```python
check = urwid.CheckBox("启用")
urwid.connect_signal(check, "change", lambda w, state: print(state))

group = []
urwid.RadioButton(group, "选项 A")
urwid.RadioButton(group, "选项 B")
```

### 计数器示例

```python
import urwid

count = 0
display = urwid.Text("0", align="center")

def change(delta):
    global count
    count += delta
    display.set_text(str(count))

def quit_app(key):
    if key == "q":
        raise urwid.ExitMainLoop()

body = urwid.Filler(urwid.Pile([
    urwid.Text("计数器", align="center"),
    urwid.Columns([
        urwid.Button("-", on_press=lambda _: change(-1)),
        urwid.Button("+", on_press=lambda _: change(1)),
    ]),
    display,
]), valign="middle")

urwid.MainLoop(body, unhandled_input=quit_app).run()
```

## 列表与焦点

`ListBox` 本身不保存内容，需要 `ListWalker`：

```python
def menu_item(label):
    button = urwid.Button(label)
    urwid.connect_signal(button, "click", lambda b: footer.set_text(label))
    return urwid.AttrMap(button, None, focus_map="focus")

walker = urwid.SimpleFocusListWalker([
    menu_item("新建"),
    menu_item("打开"),
    menu_item("退出"),
])
listbox = urwid.ListBox(walker)
```

- `walker.focus` 读写当前焦点索引。
- `walker.set_focus(n)` 移动焦点。
- `ListBox` 自动处理上下方向键、PageUp/PageDown。

## 调色板与样式

```python
palette = [
    ("header", "white", "dark blue"),
    ("footer", "black", "light gray"),
    ("focus", "black", "light cyan"),
    ("error", "light red", "black"),
    ("accent", "#ff8800", "#222222"),   # 真彩色
    ("256color", "h123", "h235"),       # 256 色
]
```

- 16 色名称：`black`、`dark red`、`dark green`、`brown`、`dark blue`、`dark magenta`、`dark cyan`、`light gray`、`dark gray`、`light red`、`light green`、`yellow`、`light blue`、`light magenta`、`light cyan`、`white`。
- 256 色：`h0` ~ `h255`。
- 真彩色：`#rrggbb`。
- 应用：`urwid.AttrMap(widget, "header")`；聚焦态用 `focus_map="focus"`。

## 全局按键与 `unhandled_input`

控件没处理的按键会交给 `MainLoop` 的 `unhandled_input`：

```python
def global_keys(key):
    if key in ("q", "Q"):
        raise urwid.ExitMainLoop()
    if key == "f1":
        show_help()

urwid.MainLoop(widget, palette, unhandled_input=global_keys).run()
```

也可以在自定义控件中重写 `keypress(size, key)`：

```python
class KeyView(urwid.WidgetWrap):
    def __init__(self):
        self.text = urwid.Text("按任意键")
        super().__init__(self.text)

    def selectable(self):
        return True

    def keypress(self, size, key):
        self.text.set_text(f"按键：{key}")
        return key   # 返回 key 表示未消费，继续向上传递
```

## 定时器与异步

### 定时器

```python
def tick(loop, user_data):
    clock.set_text(time.strftime("%H:%M:%S"))
    loop.set_alarm_in(1, tick)

loop = urwid.MainLoop(widget)
loop.set_alarm_in(1, tick)
loop.run()
```

### 接入 asyncio

```python
import asyncio
import urwid
from urwid.event_loop.asyncio_loop import AsyncioEventLoop

async def main():
    loop = urwid.MainLoop(widget, event_loop=AsyncioEventLoop())
    loop.run()

asyncio.run(main())
```

耗时逻辑建议放到异步任务或线程中，再用 `loop.set_alarm_in` / 队列把结果推回 UI 线程。

## 自定义控件

继承 `urwid.WidgetWrap` 包装现有控件，或继承 `urwid.Widget` 自行实现 `rows()`、`render()`、`keypress()`。大多数场景用 `WidgetWrap` 即可：

```python
class LabeledBox(urwid.WidgetWrap):
    def __init__(self, label: str):
        self.label = urwid.Text(label)
        self.body = urwid.Text("")
        super().__init__(urwid.Pile([self.label, self.body]))

    def set_value(self, value: str) -> None:
        self.body.set_text(value)
```

需要向外发信号时，先 `urwid.register_signal(MyWidget, ["changed"])`，再调用 `urwid.emit_signal(self, "changed", value)`。

## 开发与调试

- 用 `python app.py` 直接运行；urwid 会接管终端，异常时可能留下乱码，建议用 `try/finally` 或在 `MainLoop` 外层捕获。
- 通过 `screen = urwid.raw_display.Screen()` 可自定义屏幕后端。
- 调试输出不要直接 `print`，会破坏界面；可写入文件或使用日志。
- 终端建议使用支持 256 色 / 真彩色的环境（Windows Terminal、iTerm2、Kitty 等）。

## 注意事项

1. **`ListBox` 必须配合 `ListWalker`**，不能直接传控件列表。
2. **`MainLoop.run()` 是阻塞的**，退出靠 `urwid.ExitMainLoop()`。
3. **`unhandled_input` 只接收未被控件消费的按键**，若控件返回了按键则会继续冒泡。
4. **`AttrMap` 的 `focus_map`** 只在控件获得焦点时生效。
5. **修改控件后无需手动刷新**，urwid 会在事件循环中重绘；在循环外修改需调用 `loop.draw_screen()`。
6. **终端尺寸变化**会触发布局重算，自定义控件应正确处理 `size` 参数。
7. **urwid 不提供现成的表格/树等高级控件**，复杂界面需要自己组合或使用 `urwid_tree` 等扩展。

## 与其它 TUI 库对比

| 维度 | urwid | Textual | curses | prompt_toolkit |
| --- | --- | --- | --- | --- |
| 抽象层级 | 中（控件 + 容器） | 高（组件 + CSS） | 低（字符网格） | 中（输入/布局） |
| 样式能力 | 中（palette + AttrMap） | 强（TCSS） | 手写属性 | 有限 |
| 异步支持 | 可接入 asyncio | 原生 | 无 | 部分 |
| 学习曲线 | 中 | 中 | 陡 | 中 |
| 适合场景 | 传统终端控件界面 | 现代终端应用 | 底层控制 | 交互式命令行 |

更多 TUI 方案见 [[../../../../../杂记/学习笔记/TUI/TUI 笔记]]。
