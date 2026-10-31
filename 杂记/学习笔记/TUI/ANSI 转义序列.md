---
date: 2026-10-31
related:
  - "[[TUI 笔记]]"
  - "[[Python 笔记]]"
tags:
  - python
  - tui
  - terminal
  - ansi
---
# ANSI 转义序列

ANSI 转义序列（ANSI escape sequence）是终端里用特殊字节流控制**光标、颜色、清屏、标题**等行为的协议。它不是「打印出来的文字」，而是给终端的指令；`curses`、`textual`、`rich` 等库最终都会生成这些序列。

## 基本结构

一条序列通常以 `ESC`（`0x1B`，写作 `\x1b` / `\033` / `\e`）开头，后面跟不同的引导符：

| 引导符 | 名称 | 用途 |
| --- | --- | --- |
| `ESC [` | CSI（Control Sequence Introducer） | 光标移动、擦除、SGR 颜色等，最常用 |
| `ESC ]` | OSC（Operating System Command） | 设置窗口标题、超链接、剪贴板 |
| `ESC P … ESC \` | DCS（Device Control String） | 设备控制、终端查询回复 |
| `ESC (` / `ESC )` | 字符集切换 | 选择 G0/G1 字符集，基本已过时 |
| 单字符 | Fe / Fs 类 | `ESC 7` 保存光标、`ESC 8` 恢复、`ESC c` 复位终端 |

CSI 的完整格式：

```
ESC [ 参数 ; 参数 … 中间字节 终止字节
```

- **参数**：数字，省略时取默认值（通常是 `1` 或 `0`）。
- **中间字节**：`0x20–0x2F`，如 `?`、`>`，用于私有模式。
- **终止字节**：`0x40–0x7E`，决定具体动作，如 `H`、`m`、`J`。

例：`ESC[1;31m` = `\x1b[1;31m`，参数 `1`（加粗）和 `31`（红色），终止字节 `m`（SGR）。

## 光标移动（CSI）

坐标统一按 **行;列** 书写（1 基），与 `curses` 的 `(y, x)` 顺序一致。

| 序列 | 含义 |
| --- | --- |
| `ESC[{n}A` | 光标上移 n 行（CUU） |
| `ESC[{n}B` | 下移 n 行（CUD） |
| `ESC[{n}C` | 右移 n 列（CUF） |
| `ESC[{n}D` | 左移 n 列（CUB） |
| `ESC[{n}E` | 移到下 n 行行首（CNL） |
| `ESC[{n}F` | 移到上 n 行行首（CPL） |
| `ESC[{n}G` | 移到第 n 列（CHA） |
| `ESC[{row};{col}H` | 光标定位（CUP），等价 `f` |
| `ESC[s` / `ESC[u` | 保存 / 恢复光标位置（SCP/RCP） |
| `ESC 7` / `ESC 8` | 同上，DEC 版本 |
| `ESC[{top};{bottom}r` | 设置滚动区域（DECSTBM），只在该区间内滚动 |

行首、行尾控制：

| 序列 | 含义 |
| --- | --- |
| `\r` | 回到行首（CR） |
| `\n` | 换行（LF）；终端通常还带 CR，取决于模式 |
| `ESC D` | 索引：下移一行，必要时滚动（IND） |
| `ESC M` | 反向索引：上移一行，必要时滚动（RI） |
| `ESC E` | 下一行行首（NEL） |

## 擦除与编辑（CSI）

| 序列 | 含义 |
| --- | --- |
| `ESC[2J` | 清屏（ED 2） |
| `ESC[3J` | 连同回滚缓冲区一起清除（ED 3） |
| `ESC[K` / `ESC[0K` | 清除光标到行尾（EL 0） |
| `ESC[1K` | 清除行首到光标（EL 1） |
| `ESC[2K` | 清除整行（EL 2） |
| `ESC[{n}J` | `0` 光标到屏幕末尾，`1` 屏幕开头到光标，`2` 全部 |
| `ESC[{n}X` | 擦除 n 个字符（用空格覆盖，光标不动） |
| `ESC[{n}P` | 删除 n 个字符，后续字符左移 |
| `ESC[{n}@` | 插入 n 个空白字符 |
| `ESC[{n}L` / `ESC[{n}M` | 在光标行插入 / 删除 n 行 |
| `ESC[{n}S` / `ESC[{n}T` | 整屏上滚 / 下滚 n 行 |

清屏 + 归位是最常见的组合：

```python
print("\x1b[2J\x1b[H", end="")   # 清屏并把光标移到左上角
```

## SGR：颜色与文本样式

SGR（Select Graphic Rendition）以 `m` 结尾，多个属性用 `;` 连接，一次可设多个。

| 代码 | 含义 |
| --- | --- |
| `0` | 重置所有属性 |
| `1` / `2` | 加粗 / 暗淡 |
| `3` / `23` | 斜体 / 关闭斜体 |
| `4` / `24` | 下划线 / 关闭下划线 |
| `5` | 闪烁（支持很差） |
| `7` / `27` | 反显（前景背景互换）/ 关闭 |
| `8` / `28` | 隐藏 / 关闭隐藏 |
| `9` / `29` | 删除线 / 关闭 |
| `30–37` | 前景 8 色 |
| `90–97` | 前景亮色（bright） |
| `40–47` | 背景 8 色 |
| `100–107` | 背景亮色 |
| `39` / `49` | 恢复默认前景 / 背景 |

256 色与真彩色使用**扩展参数**：

```
ESC[38;5;{n}m      # 前景，256 色索引 n（0–255）
ESC[48;5;{n}m      # 背景，256 色
ESC[38;2;{r};{g};{b}m   # 前景，真彩色
ESC[48;2;{r};{g};{b}m   # 背景，真彩色
```

等价的冒号写法 `ESC[38:2::r:g:b m` 更规范（避免与 `;` 参数混淆），但兼容性不如分号写法。

256 色索引分布：

- `0–7` 基础 8 色，`8–15` 亮色。
- `16–231` 为 6×6×6 色立方，公式 `16 + 36r + 6g + b`（r/g/b ∈ 0–5）。
- `232–255` 为 24 级灰阶。

```python
RED = "\x1b[31m"
BOLD = "\x1b[1m"
RESET = "\x1b[0m"

print(f"{BOLD}{RED}错误：{RESET} 文件不存在")
print("\x1b[38;2;255;128;0m橙色真彩\x1b[0m")
print("\x1b[48;5;236m深灰背景\x1b[0m")
```

要点：

- **一定要在结尾重置**（`\x1b[0m`），否则样式会「漏」到后续输出。
- 只重置颜色可用 `39` / `49`，避免把用户的加粗等设置一起清掉。
- 颜色是否生效取决于终端：真彩色需要 `COLORTERM=truecolor`（或 `24bit`），256 色需要 `TERM` 含 `256color`。

## OSC：终端级操作

OSC 以 `ESC ]` 开头，用 `BEL`（`\a`）或 `ESC \`（ST）结束。

| 序列 | 用途 |
| --- | --- |
| `ESC]0;标题 BEL` | 设置窗口标题和图标名 |
| `ESC]2;标题 BEL` | 只设窗口标题 |
| `ESC]8;;URL BEL 文本 ESC]8;; BEL` | 超链接（终端需支持） |
| `ESC]52;c;{base64} BEL` | 写系统剪贴板（常被安全策略禁用） |
| `ESC]4;{n};rgb:.. BEL` | 修改调色板第 n 号颜色 |
| `ESC]10;? BEL` / `ESC]11;? BEL` | 查询前景 / 背景色，终端以 OSC 回复 |
| `ESC]1337;...` | iTerm2 私有扩展（图像、标记等） |

```python
print("\x1b]2;我的 TUI 应用\x07", end="")
print("\x1b]8;;https://example.com\x07链接\x1b]8;;\x07")
```

## DEC 私有模式

以 `ESC[?{n}h` 开启、`ESC[?{n}l` 关闭。

| 模式 | 含义 |
| --- | --- |
| `?25h` / `?25l` | 显示 / 隐藏光标（DECTCEM） |
| `?1049h` / `?1049l` | 进入 / 退出备用屏幕（保留原屏幕内容） |
| `?47h` / `?47l` | 切换备用屏幕（旧写法，不保存内容） |
| `?1047h` / `?1047l` | 切换备用屏幕（不清屏版本） |
| `?2004h` / `?2004l` | 括号粘贴模式（bracketed paste） |
| `?1000h` | 开启鼠标点击上报 |
| `?1002h` | 按钮拖动上报 |
| `?1003h` | 任意移动上报 |
| `?1006h` | SGR 扩展鼠标坐标（推荐配合上面使用） |
| `?7h` / `?7l` | 自动换行开关 |
| `?1049h` 组合 | 大多数全屏 TUI 的进入方式 |

全屏程序的标准开场与收尾：

```python
ENTER = "\x1b[?1049h\x1b[?25l\x1b[2J\x1b[H"   # 备用屏、藏光标、清屏
EXIT  = "\x1b[0m\x1b[?25h\x1b[?1049l"          # 重置样式、显光标、回主屏

print(ENTER, end="", flush=True)
try:
    ...  # 绘制界面、读事件
finally:
    print(EXIT, end="", flush=True)   # 异常时也要恢复，否则终端会「坏掉」
```

## 查询与应答

终端也能回话，读取时要注意这些字节会混在按键输入里：

| 序列 | 含义 |
| --- | --- |
| `ESC[6n` | 查询光标位置，回复 `ESC[{row};{col}R` |
| `ESC[c` / `ESC[>c` | 查询设备属性（DA1/DA2） |
| `ESC[5n` | 查询终端状态，回复 `ESC[0n` 表示正常 |
| `ESC[18t` | 查询文本区域尺寸，回复 `ESC[8;{rows};{cols}t` |

```python
import sys

sys.stdout.write("\x1b[6n")
sys.stdout.flush()
reply = sys.stdin.read(8)     # 形如 "\x1b[12;40R"
```

实际项目里通常直接用 `shutil.get_terminal_size()` 或 `os.get_terminal_size()`，不必自己解析。

## 跨平台与检测

**Windows**：Windows 10 起支持 VT 序列，但需要先开启：

```python
import ctypes, os

kernel32 = ctypes.windll.kernel32
handle = kernel32.GetStdHandle(-11)          # STD_OUTPUT_HANDLE
mode = ctypes.c_uint32()
kernel32.GetConsoleMode(handle, ctypes.byref(mode))
kernel32.SetConsoleMode(handle, mode.value | 0x0004)   # ENABLE_VIRTUAL_TERMINAL_PROCESSING
```

更简单的写法是 `os.system("")`（在 Windows 上会顺带初始化 VT 支持），或依赖 `colorama.init()`、`rich` 自动处理。

**能力检测**：

- `sys.stdout.isatty()`：不是 TTY（重定向到文件/管道）就别输出颜色。
- 环境变量 `NO_COLOR`（非空即禁用）、`FORCE_COLOR`、`CLICOLOR`。
- `TERM=dumb` 或缺失时视为不支持。
- 颜色深度：`COLORTERM` 含 `truecolor`/`24bit`；否则看 `TERM` 是否含 `256color`；再退回 16 色。
- `curses.tigetnum("colors")` 可读取 terminfo 中的颜色数。
- Python 库：`rich.console.Console().color_system`、`supports-color`。

## 与现代库的关系

| 库 | 关系 |
| --- | --- |
| `curses` | 通过 terminfo 生成序列，跨终端兼容性最好 |
| `blessed` | 对 terminfo + 序列的友好封装，可直接发原始序列 |
| `rich` | 内部用 `Segment` + 样式生成 SGR，非 TTY 时自动降级 |
| `textual` | 基于 Rich 渲染，再用序列控制备用屏、鼠标、resize |
| `prompt_toolkit` | 自己维护输出缓冲和差分刷新，底层仍是这些序列 |

因此一般**不必手写序列**；只有做极简工具、调试渲染问题或写终端封装层时才直接拼。

## 常见坑

- **忘记重置**：`\x1b[31m` 之后没 `\x1b[0m`，后续提示符都变红。
- **异常退出没恢复**：备用屏 / 隐藏光标必须放在 `finally` 里，或使用 `curses.wrapper`、`contextlib` 兜底。
- **宽度算错**：CJK 字符、emoji 占 2 列，`len()` 不准；需 `wcwidth` 或 `unicodedata.east_asian_width`。
- **序列被原样打印**：Windows 未开 VT、`TERM=dumb`、日志文件里都会看到 `←[31m` 这类乱码。
- **`\e` 不可移植**：Python 用 `\x1b` 或 `\033`，JS/Go/Rust 用 `\x1b`，C 用 `\033`。
- **tmux / screen 吞序列**：部分序列需透传，格式为 `ESC P tmux; ESC <序列> ESC \`。
- **多路复用下的真彩色**：tmux 需 `set -g default-terminal "tmux-256color"` 与 `terminal-features` 配置。
- **闪烁与性能**：频繁 `2J` + 重绘会闪；应只移动光标改变化的局部。

## 相关笔记

- [[TUI 笔记]]：全屏终端界面的整体概念与库对比。
- [[Python 笔记]]：语言层面的输出与标准库用法。
