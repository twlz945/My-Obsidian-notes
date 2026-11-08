---
title: Python Textual 库
date: 2026-10-31
tags:
  - Python
  - Textual
  - TUI
  - 教程
aliases:
  - Textual
  - textual
  - Python TUI
related:
  - "[[../../../../../杂记/学习笔记/TUI/TUI 笔记]]"
  - "[[Python 笔记]]"
---

# Python Textual 库

[Textual](https://textual.textualize.io/) 是 Textualize 团队开发的 Python TUI（Text User Interface）框架，构建在 [[Rich]] 的渲染能力之上。它用**组件树 + 类 CSS 样式 + 异步事件**的方式编写全屏终端应用，支持鼠标、动画、跨平台，是目前 Python 生态中最现代的 TUI 方案之一。

与 `curses` 这类底层库不同，Textual 提供现成控件、布局系统和样式表，适合快速开发终端工具、监控面板、数据库客户端等应用。

## 核心要点

- 应用继承 `App`，在 `compose()` 中 `yield` 组件树。
- 布局与外观用 CSS（`.tcss` 文件或 `CSS` 变量）描述，支持选择器、变量、伪类。
- 状态用 `reactive` 声明，变化时自动触发 `watch_*` 与重绘。
- 交互通过事件（`on_*` 方法或 `@on` 装饰器）和自定义 `Message` 完成。
- 耗时任务交给 `@work` 异步 worker，避免阻塞 UI。
- 内置测试工具 `App.run_test()` + `Pilot`，可模拟点击和按键。
- 依赖 `textual` 包；`textual-dev` 提供 `textual run --dev`、`textual console` 等开发命令。

## 安装

```bash
pip install textual
pip install textual-dev   # 开发工具：textual run / console / colors 等
```

验证：

```bash
python -c "import textual; print(textual.__version__)"
```

## 最小应用

```python
from textual.app import App, ComposeResult
from textual.widgets import Footer, Header, Static

class HelloApp(App):
    TITLE = "Hello"
    SUB_TITLE = "Textual Demo"
    BINDINGS = [("q", "quit", "退出")]

    def compose(self) -> ComposeResult:
        yield Header()
        yield Static("Hello, Textual!", id="hello")
        yield Footer()

if __name__ == "__main__":
    HelloApp().run()
```

运行：

```bash
python app.py
textual run --dev app.py   # 开发模式：热重载 + 调试控制台
```

`compose()` 只负责声明组件，不要在里做耗时操作；应用启动后 Textual 进入自己的事件循环。

## 应用生命周期

| 阶段 / 方法 | 作用 |
| --- | --- |
| `compose()` | 声明并返回组件树 |
| `on_mount()` | 组件挂载完成后调用，适合初始化数据 |
| `run()` | 启动事件循环（阻塞） |
| `exit()` / `action_quit()` | 退出应用 |
| `on_unmount()` | 退出前清理资源 |

```python
class MyApp(App):
    def on_mount(self) -> None:
        self.query_one("#hello", Static).update("已加载")
```

## 布局与 CSS

Textual 的样式语法接近 CSS，可直接写在 `CSS` 变量里，也可放到同名 `.tcss` 文件：

```python
class LayoutApp(App):
    CSS = """
    Screen {
        align: center middle;
    }

    #box {
        width: 40;
        height: 7;
        border: round $accent;
        padding: 1 2;
    }

    .title {
        text-style: bold;
        color: $text;
    }
    """
```

常用能力：

- **选择器**：类型（`Button`）、ID（`#ok`）、类（`.primary`）、伪类（`:hover`、`:focus`）。
- **单位**：字符格、`%`、`fr`、`vw` / `vh`、`auto`。
- **盒模型**：`width` / `height` / `padding` / `margin` / `border`。
- **对齐**：`align`、`content-align`、`text-align`。
- **变量**：`$primary`、`$accent`、`$surface`、`$text` 等主题变量。

容器组件：

```python
from textual.containers import Horizontal, Vertical, Grid

def compose(self) -> ComposeResult:
    with Horizontal():
        yield Static("左", classes="pane")
        yield Static("右", classes="pane")
    with Vertical():
        yield Static("上")
        yield Static("下")
```

## 常用组件

| 组件 | 用途 |
| --- | --- |
| `Static` / `Label` | 文本、Markdown、Rich 渲染内容 |
| `Button` | 按钮 |
| `Input` | 单行输入 |
| `TextArea` | 多行编辑器 |
| `Checkbox` / `Switch` | 开关与勾选 |
| `Select` / `OptionList` | 下拉选择、选项列表 |
| `ListView` | 可滚动列表 |
| `DataTable` | 表格（排序、光标、单元格） |
| `Tree` | 树形结构 |
| `Log` / `RichLog` | 日志输出 |
| `ProgressBar` / `Sparkline` | 进度与趋势 |
| `Markdown` | Markdown 渲染 |
| `TabbedContent` / `ContentSwitcher` | 标签页与内容切换 |
| `Header` / `Footer` | 标题栏与快捷键栏 |

## 事件与交互

### `on_*` 方法

```python
from textual.widgets import Button, Static

class CounterApp(App):
    count = 0

    def compose(self) -> ComposeResult:
        yield Static("0", id="count")
        with Horizontal():
            yield Button("-", id="dec")
            yield Button("+", id="inc")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        self.count += 1 if event.button.id == "inc" else -1
        self.query_one("#count", Static).update(str(self.count))
```

### `@on` 装饰器

```python
from textual import on

@on(Button.Pressed, "#inc")
def increment(self) -> None:
    self.count += 1
```

### 自定义消息

```python
from textual.message import Message

class Submitted(Message):
    def __init__(self, text: str) -> None:
        super().__init__()
        self.text = text

# 在某个组件内发送
self.post_message(Submitted(value))

# 在父级处理
def on_submitted(self, message: Submitted) -> None:
    self.notify(f"收到：{message.text}")
```

## 响应式状态

`reactive` 声明的属性变化时会自动重绘，并可绑定 `watch_*` / `compute_*`：

```python
from textual.reactive import reactive

class Clock(App):
    seconds = reactive(0)

    def watch_seconds(self, value: int) -> None:
        self.query_one("#time", Static).update(f"{value}s")

    def on_mount(self) -> None:
        self.set_interval(1, lambda: setattr(self, "seconds", self.seconds + 1))
```

- `watch_<attr>(old, new)`：值变化时调用。
- `compute_<attr>()`：派生值。
- `validate_<attr>()`：赋值前校验。

## 异步与 Worker

耗时操作（网络、文件、数据库）应放到 worker，避免卡住事件循环：

```python
from textual import work

class LoaderApp(App):
    @work(exclusive=True)
    async def load_data(self) -> None:
        data = await fetch()
        self.query_one("#result", Static).update(str(data))

    def on_mount(self) -> None:
        self.load_data()
```

`exclusive=True` 表示同一 worker 组内只保留最新任务；也可用 `self.run_worker(...)` 手动管理。

## 屏幕与导航

Textual 用「屏幕栈」管理页面：

```python
from textual.screen import ModalScreen, Screen

class DetailScreen(Screen):
    ...

self.push_screen(DetailScreen())   # 入栈
self.pop_screen()                  # 出栈
self.switch_screen(DetailScreen()) # 替换当前屏幕
```

模态对话框继承 `ModalScreen[T]`，可通过 `push_screen(screen, callback)` 获取返回值。

## 测试

```python
import pytest
from textual.pilot import Pilot

@pytest.mark.asyncio
async def test_counter():
    app = CounterApp()
    async with app.run_test() as pilot:
        await pilot.click("#inc")
        await pilot.press("tab")
        assert app.count == 1
```

`Pilot` 支持 `click()`、`press()`、`pause()`，可对组件和快捷键做端到端测试。

## 开发与调试

```bash
textual run --dev app.py   # 热重载 + 可连接调试控制台
textual console            # 在另一个终端查看日志
textual colors             # 查看可用颜色
textual keys               # 查看按键名称
```

代码中也可用 `self.log(...)`、`self.notify(...)` 输出日志和提示。

## 注意事项

1. **不要在 `compose()` 中做耗时操作**，会阻塞首次渲染。
2. **更新 UI 用响应式属性或 `update()`**，不要直接改内部状态后指望自动刷新。
3. **CSS 优先级**：内联 `styles` > ID > 类 > 类型；冲突时检查选择器。
4. **终端兼容性**：真彩色、鼠标、Unicode 宽度依赖终端，Windows Terminal / iTerm2 / Kitty 支持较好。
5. **`textual` 与 `textual-dev` 分开安装**，后者只用于开发调试。
6. **Textual 不是 Rich**：Rich 负责富文本输出，Textual 才是全屏应用框架；二者可配合使用。

## 与其它 TUI 库对比

| 维度 | Textual | curses | prompt_toolkit | urwid |
| --- | --- | --- | --- | --- |
| 抽象层级 | 高（组件 + CSS） | 低（字符网格） | 中（输入/布局） | 中（控件） |
| 样式能力 | 强（TCSS） | 手写属性 | 有限 | 有限 |
| 异步支持 | 原生 | 无 | 部分 | 无 |
| 学习曲线 | 中 | 陡 | 中 | 中 |
| 适合场景 | 现代终端应用 | 底层控制 | 交互式命令行 | 传统控件界面 |

更多 TUI 方案见 [[../../../../../杂记/学习笔记/TUI/TUI 笔记]]。
