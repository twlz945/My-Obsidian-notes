---
date: 2026-11-13
related:
  - "[[ANSI 转义序列]]"
  - "[[TUI 笔记]]"
tags:
  - ansi
  - terminal
  - tui
  - reference
---

# ANSI 转义序列完全参考

> 面向开发者 / 终端实现者 / 运维的实用手册。
> 覆盖 ECMA-48 语法、VT100/VT220/xterm 语义、现代终端扩展（真彩色、OSC 8、OSC 52、模式 2026、Kitty 键盘协议）以及安全与调试。
>
> 记法约定：`ESC` = `0x1B`，`CSI` = `ESC [`，`OSC` = `ESC ]`，`DCS` = `ESC P`，`APC` = `ESC _`，`ST` = `ESC \`，`BEL` = `0x07`。
> 文中 `CSI 1;31 m` 意为字节序列 `ESC [ 1 ; 3 1 m`。

---

## 目录

1. [[#1. 它是什么]]
2. [[#2. 标准与历史]]
3. [[#3. 语法总览]]
4. [[#4. C0 / C1 控制字符]]
5. [[#5. 光标移动与定位（CSI）]]
6. [[#6. 擦除与编辑]]
7. [[#7. 滚动区域与滚动]]
8. [[#8. 制表位]]
9. [[#9. 保存 / 恢复 / 复位]]
10. [[#10. 模式设置（SM/RM、DECSET/DECRST）]]
11. [[#11. SGR：字符属性与颜色]]
12. [[#12. 光标样式（DECSCUSR）]]
13. [[#13. 字符集与 DEC 绘图字符]]
14. [[#14. 设备查询与上报]]
15. [[#15. OSC：操作系统命令]]
16. [[#16. DCS / APC / PM / SOS]]
17. [[#17. 键盘输入、鼠标、粘贴]]
18. [[#18. 现代扩展]]
19. [[#19. 兼容性速览]]
20. [[#20. 安全：转义序列注入]]
21. [[#21. 调试与工具]]
22. [[#22. 代码示例]]
23. [[#23. 速查表]]
24. [[#24. 参考资料]]

---


## 1. 它是什么

**ANSI 转义序列**（ANSI escape sequences）是嵌入在文本流中的、以 `ESC`（`0x1B`）开头的控制指令。终端模拟器读到它时**不打印字符**，而是执行动作：移动光标、改颜色、清屏、切屏、设标题、改剪贴板……

```text
普通文本 ──► 终端 ──► 显示
ESC [ 1 ; 31 m  ──► 终端 ──► 后续文字变粗体红色
```

它本质上是「带内信令」（in-band signaling）：控制信息与数据走同一条字节流。这带来两个后果：

- **优点**：任何能传字节的通道（串口、SSH、`printf`、日志文件）都能传控制指令，无需额外协议。
- **缺点**：数据与指令不可区分 → 不可信内容里的转义序列会被执行（见 [[#20. 安全：转义序列注入|第 20 节]]）。

严格说「ANSI 转义序列」是个俗称：规范名是 **ECMA-48 / ISO 6429 控制函数**，加上 **DEC VT 系列**的私有扩展，再加现代终端厂商的私有扩展。

---

## 2. 标准与历史

| 年代 | 事件 |
|---|---|
| 1960s | ASCII（ANSI X3.4）定义 C0 控制字符：`BEL`、`BS`、`CR`、`LF`… |
| 1976 | ECMA-48 第 1 版（当时叫 ANSI X3.64），定义 `ESC` 序列与 CSI |
| 1978 | DEC VT100 发布，把 `CSI` 序列做成事实标准（`ESC [ H` 定位、`ESC [ m` 属性） |
| 1983 | VT220：引入 `DECSCUSR`、字符集切换、更多私有模式 |
| 1987–1991 | ECMA-48 第 3/4/5 版：补全 SGR 复位码（22–29、39、49）、OSC、DCS |
| 1988 | ISO 8613-6（ITU T.416）定义 `38;2` 真彩色子参数语法 |
| 1990s | xterm 成为 X11 事实参考实现，定义 `ctlseqs` 文档与大量 `XT*` 扩展 |
| 2000s | Linux console、rxvt/urxvt、Konsole 各自扩展 |
| 2010s | VTE（GNOME Terminal）、iTerm2、Alacritty、Windows Terminal 跟进 |
| 2020s | Kitty / WezTerm / foot / Ghostty 推动新扩展：真彩色、剪贴板、超链接、同步刷新、Kitty 键盘协议 |

**关键认知**：没有「唯一权威的现代 ANSI 标准」。实际行为 = ECMA-48（语义骨架）+ xterm `ctlseqs`（事实参考）+ 各终端自己的实现差异。写跨终端代码时，以 terminfo 和实测为准。

---

## 3. 语法总览

### 3.1 字节分类

ECMA-48 把字节按区间分类，解析器据此判断当前处于序列的哪一段：

| 区间 | 名称 | 用途 |
|---|---|---|
| `0x00–0x1F` | C0 控制字符 | 单字节控制：`BEL` `BS` `HT` `LF` `CR` `ESC` 等 |
| `0x20–0x2F` | 中间字节（intermediate） | `SP ! " # $ % & ' ( ) * + , - . /`，修饰序列语义 |
| `0x30–0x3F` | 参数字节（parameter） | 数字 `0-9`，分隔符 `;` `:`，私有标记 `< = > ?` |
| `0x40–0x7E` | 终止字节（final） | 决定序列功能，如 `A` `H` `m` `J` |
| `0x7F` | DEL | 通常被忽略 |
| `0x80–0x9F` | C1 控制字符 | 8 位形式的 `CSI` `OSC` `DCS` 等 |
| `0xA0–0xFF` | GR 图形字符 | 高位字符集（UTF-8 或 ISO 8859） |

### 3.2 序列形式

```text
① 单字符：        ESC 后接一个 0x20–0x7E 的字节       例：ESC c（复位）、ESC 7（保存光标）
② CSI 序列：      ESC [ 参数 中间字节 终止字节        例：ESC [ 1 ; 31 m
③ 字符串序列：    ESC ] / ESC P / ESC _ / ESC ^ / ESC X  ... 终止符 ST 或 BEL
④ 字符集指定：    ESC ( C / ESC ) C / ESC * C / ESC + C   例：ESC ( 0（DEC 绘图集）
⑤ ESC 空格序列：  ESC SP F（7 位 C1）、ESC SP G（8 位 C1）
```

### 3.3 CSI 的完整语法

```text
CSI  P           I           F
 |    |           |           |
ESC [ [私有用] [参数字节] [中间字节] [终止字节]
       < = > ?    0-9 ; :     0x20-0x2F   0x40-0x7E
```

- **私有用（private marker）**：`<`（SGR 鼠标、Kitty 键盘）、`=`、`>`（xterm 扩展）、`?`（DEC 私有模式、DEC 查询）。挂在参数最前面。
- **参数**：十进制数字，`;` 分隔多个参数。**省略或为空 = 默认值**（通常为 1 或 0）。
  - `CSI ; 5 H` = 行取默认（1），列 5。
  - `CSI 0 J` 与 `CSI J` 等价。
- **子参数**：`:` 分隔，用于 SGR 颜色（`38:2::255:0:0`）等 ITU T.416 语法。
- **中间字节**：`SP`（`0x20`）最常见：`CSI 2 SP q`（光标样式）、`CSI ! p`（软复位）、`CSI $ q`（DECRQSS）。

常见形态对照：

| 写法 | 含义 |
|---|---|
| `ESC [ 2 J` | 擦除整个屏幕 |
| `ESC [ ? 25 l` | 隐藏光标（DEC 私有模式） |
| `ESC [ ? 1049 h` | 进入备用屏幕 |
| `ESC [ > 0 q` | 查询终端版本（XTVERSION） |
| `ESC [ 1 ; 5 A` | 光标上移 1 行，带 Ctrl 修饰（键盘上报用） |
| `ESC [ 38 : 2 : : 255 : 0 : 0 m` | 真彩色前景（标准写法） |
| `ESC [ 2 SP q` | 光标设为「稳定方块」 |

### 3.4 7 位 vs 8 位

每个 C1 功能都有两种写法：

| 8 位 | 7 位等价 | 名称 |
|---|---|---|
| `0x9B` | `ESC [` | CSI |
| `0x9D` | `ESC ]` | OSC |
| `0x90` | `ESC P` | DCS |
| `0x9C` | `ESC \` | ST |
| `0x84` | `ESC D` | IND（下移一行） |
| `0x85` | `ESC E` | NEL（下一行行首） |
| `0x88` | `ESC H` | HTS（设制表位） |
| `0x8D` | `ESC M` | RI（上移一行） |
| `0x8E` / `0x8F` | `ESC N` / `ESC O` | SS2 / SS3（单次移入 G2/G3） |
| `0x98` | `ESC X` | SOS |
| `0x9E` | `ESC ^` | PM |
| `0x9F` | `ESC _` | APC |

**实践建议**：**永远输出 7 位形式**。原因：在 UTF-8 模式下 `0x80–0x9F` 是合法的 UTF-8 续字节，8 位 C1 会被误解析（这是 xterm `ctlseqs` 明确警告的坑）。同理，解析器不要假设输入是纯 ASCII。

### 3.5 解析器模型（自己实现时）

经典实现是**模态状态机**（Paul Williams 的 VT500 parser 是事实标准）：

```text
GROUND ──ESC──► ESCAPE ──'['──► CSI_ENTRY ──参数/中间──► CSI_PARAM ──终止字节──► GROUND
   │                │                 └──非法字节──► GROUND（丢弃）
   ├──'['(0x9B)──► CSI_ENTRY
   ├──']'──► OSC_STRING ──BEL/ST──► GROUND
   ├──'P'──► DCS_ENTRY ──...──► DCS_PASSTHROUGH ──ST──► GROUND
   └──'_'──► APC_STRING ──ST──► GROUND
```

要点：

- 进入字符串模式（OSC/DCS/APC/PM/SOS）后，**直到 `ST` 才结束**；OSC 传统上也接受 `BEL` 作为结束符（xterm 两者都收，回显时用查询方的终止符）。
- 字符串内容里出现 `ESC` 但下一字节不是 `\` → 按错误处理（重置回 GROUND 或忽略）。
- 参数缓冲区要有上限（ECMA-48 只要求 ≥16 个参数，实际实现常设 32–256 字节上限），否则是 DoS 面。
- 对**不支持但格式合法**的序列：安静忽略（不要打印成乱码）。对**格式非法**的序列：丢弃并回 GROUND。

伪代码：

```python
def parse(data: bytes):
    i, state, params, inter = 0, "GROUND", [], b""
    while i < len(data):
        b = data[i]; i += 1
        if state == "GROUND":
            if b == 0x1B: state = "ESCAPE"
            elif b == 0x9B: state, params, inter = "CSI", [], b""
            elif b < 0x20: handle_c0(b)
            elif b == 0x7F: pass
            else: put_char(b)
        elif state == "ESCAPE":
            if b == ord("["): state = "CSI"
            elif b == ord("]"): state = "OSC"
            elif b == ord("P"): state = "DCS"
            elif b == ord("_"): state = "APC"
            else: dispatch_esc(b); state = "GROUND"
        elif state == "CSI":
            if 0x30 <= b <= 0x3F: params.append(b)
            elif 0x20 <= b <= 0x2F: inter += bytes([b])
            elif 0x40 <= b <= 0x7E: dispatch_csi(bytes(params), inter, b); state = "GROUND"
            else: state = "GROUND"
        elif state in ("OSC", "DCS", "APC"):
            if b == 0x07 and state == "OSC": finish_string(); state = "GROUND"
            elif b == 0x1B: state += "_ESC"   # 期待 '\\'
            elif state.endswith("_ESC") and b == ord("\\"): finish_string(); state = "GROUND"
            else: collect_string_byte(b)
```

---

## 4. C0 / C1 控制字符

### 4.1 C0（单字节，7/8 位通用）

| 名称 | 缩写 | 十六进制 | 含义 |
|---|---|---|---|
| NUL | `NUL` | `0x00` | 空，通常忽略 |
| BEL | `BEL` | `0x07` | 响铃 / 任务栏提醒 / 闪烁 |
| BS | `BS` | `0x08` | 退格（不擦除，只左移） |
| HT | `HT` | `0x09` | 水平制表（到下一制表位） |
| LF | `LF` | `0x0A` | 换行（**不下移列**，见 LNM 模式） |
| VT | `VT` | `0x0B` | 垂直制表，多数终端等同 LF |
| FF | `FF` | `0x0C` | 换页，多数终端等同 LF |
| CR | `CR` | `0x0D` | 回车（列归 1） |
| SO | `SO` | `0x0E` | 移出：G1 作为 GL |
| SI | `SI` | `0x0F` | 移入：G0 作为 GL |
| CAN | `CAN` | `0x18` | 取消当前序列 |
| SUB | `SUB` | `0x1A` | 替换（常作 `Ctrl-Z`） |
| ESC | `ESC` | `0x1B` | 转义序列引导符 |
| DEL | `DEL` | `0x7F` | 删除，通常被忽略 |

⚠️ **`LF` 不回车**。Unix 程序靠终端 `ONLCR`（termios）把 `\n` 翻译成 `\r\n`；如果对端是裸串口，必须自己发 `\r\n`。

### 4.2 C1（8 位控制字符）

见 [[#3.4 7 位 vs 8 位|3.4]] 的映射表。**不要发送 8 位 C1**，理由同上。

### 4.3 单字符 ESC 序列（常用）

| 序列 | 名称 | 含义 |
|---|---|---|
| `ESC 7` | DECSC | 保存光标位置 + 属性 + 字符集 |
| `ESC 8` | DECRC | 恢复光标位置 + 属性 + 字符集 |
| `ESC D` | IND | 下移一行（滚动区域内） |
| `ESC E` | NEL | 下移一行并回到行首 |
| `ESC M` | RI | 上移一行（滚动区域内，反向索引） |
| `ESC H` | HTS | 在当前位置设制表位 |
| `ESC c` | RIS | **硬复位**：清屏、重置所有模式与属性 |
| `ESC # 8` | DECALN | 屏幕对齐测试：全屏填 `E` |
| `ESC =` | DECKPAM | 应用键盘小键盘模式 |
| `ESC >` | DECKPNM | 数字键盘模式 |
| `ESC ( 0` | — | G0 指定为 DEC 绘图字符集 |
| `ESC ( B` | — | G0 指定为 ASCII |
| `ESC % G` | — | 选择 UTF-8（ISO 2022） |
| `ESC % @` | — | 选择默认（ISO 8859-1） |
| `ESC SP F` | S7C1T | 要求终端用 7 位形式回送 C1 |
| `ESC SP G` | S8C1T | 要求终端用 8 位形式回送 C1 |

---

## 5. 光标移动与定位（CSI）

| 序列 | 助记符 | 含义 | 默认参数 |
|---|---|---|---|
| `CSI Ps A` | CUU | 上移 Ps 行 | 1 |
| `CSI Ps B` | CUD | 下移 Ps 行 | 1 |
| `CSI Ps C` | CUF | 右移 Ps 列 | 1 |
| `CSI Ps D` | CUB | 左移 Ps 列 | 1 |
| `CSI Ps E` | CNL | 下移 Ps 行并到列 1 | 1 |
| `CSI Ps F` | CPL | 上移 Ps 行并到列 1 | 1 |
| `CSI Ps G` | CHA | 列绝对定位（水平绝对） | 1 |
| `CSI Ps d` | VPA | 行绝对定位 | 1 |
| `CSI Ps ; Ps H` | CUP | 定位到（行;列），**1 基** | 1;1 |
| `CSI Ps ; Ps f` | HVP | 同 CUP | 1;1 |
| ``CSI Ps ` `` | HPA | 同 CHA（反引号 `0x60`） | 1 |
| `CSI Ps a` | HPR | 同 CUF | 1 |
| `CSI Ps e` | VPR | 同 CUD | 1 |
| `CSI Ps I` | CHT | 向前 Ps 个制表位 | 1 |
| `CSI Ps Z` | CBT | 向后 Ps 个制表位 | 1 |
| `CSI s` | SCOSC | 保存光标（DECLRMM 关闭时） | — |
| `CSI u` | SCORC | 恢复光标（DECLRMM 关闭时） | — |

**注意**：

- `CUP` 的行列是 **1 基**；`CSI 1;1H` 是左上角。
- **原点模式**（`DECOM`，`CSI ? 6 h`）开启时，行号相对于滚动区域顶部，且光标不能移出滚动区域。
- `CSI s/u` 与 `ESC 7/8` 不等价：`ESC 7/8` 还保存字符集与属性，`CSI s/u` 只存位置。很多终端把二者实现为同一个槽位，不要依赖差异。
- `CSI u` 与现代 **Kitty 键盘协议** 的 `CSI ... u` 冲突；裸 `CSI u` 仍是「恢复光标」。

---

## 6. 擦除与编辑

| 序列 | 助记符 | 含义 |
|---|---|---|
| `CSI Ps J` | ED | 擦除显示：`0`=光标到末尾（默认）、`1`=开头到光标、`2`=全部、`3`=清回滚缓冲（xterm 扩展） |
| `CSI Ps K` | EL | 擦除行：`0`=光标到行尾、`1`=行首到光标、`2`=整行 |
| `CSI ? Ps J` | DECSED | 选择性擦除（受保护的单元格不被擦） |
| `CSI ? Ps K` | DECSEL | 选择性擦除行 |
| `CSI Ps X` | ECH | 擦除 Ps 个字符（用空格覆盖，光标不动） |
| `CSI Ps @` | ICH | 插入 Ps 个空白字符（右侧内容右移） |
| `CSI Ps P` | DCH | 删除 Ps 个字符（右侧内容左移） |
| `CSI Ps L` | IL | 在当前行插入 Ps 行（下方内容下移） |
| `CSI Ps M` | DL | 删除 Ps 行（下方内容上移） |
| `CSI Ps S` | SU | 向上滚动 Ps 行（进入回滚缓冲） |
| `CSI Ps T` | SD | 向下滚动 Ps 行 |
| `CSI Ps b` | REP | 重复上一个打印字符 Ps 次 |
| `CSI Ps SP @` | SL | 整行左移 Ps 列（ECMA-48） |
| `CSI Ps SP A` | SR | 整行右移 Ps 列（ECMA-48） |

**清屏惯用法**：

```bash
printf '\033[2J\033[H'      # 清屏 + 回左上角
printf '\033[H\033[2J'      # 同上（顺序对多数终端无差别）
printf '\033[3J'            # 只清回滚缓冲（xterm/多数现代终端）
```

**重绘一行（进度条 / 状态行）**：

```bash
printf '\r\033[K完成 42%%'   # 回到行首 → 擦到行尾 → 重写
```

---

## 7. 滚动区域与滚动

| 序列 | 名称 | 含义 |
|---|---|---|
| `CSI Pt ; Pb r` | DECSTBM | 设滚动区域为第 Pt 行到第 Pb 行（1 基，含端点）；无参 = 全屏 |
| `CSI ? 6 h` / `l` | DECOM | 原点模式开 / 关 |
| `CSI Ps S` / `CSI Ps T` | SU / SD | 滚动区域内容上 / 下滚 Ps 行 |
| `ESC D` / `ESC M` | IND / RI | 下 / 上移一行，在区域边界触发滚动 |

**经典用法**：`vim`、`less` 等全屏程序把滚动区域设为「第 1 行到倒数第 2 行」，最后一行留给状态栏：

```text
CSI 1 ; 23 r      # 24 行终端：滚动区 1..23
CSI 24 ; 1 H      # 光标放到第 24 行
```

⚠️ `DECSTBM` 会**把光标移到原点**（区域左上角），且 `DECOM` 关闭时行号仍是绝对行号。

---

## 8. 制表位

| 序列 | 名称 | 含义 |
|---|---|---|
| `HT`（`0x09`） | TAB | 移到下一制表位 |
| `CSI Ps I` | CHT | 前进 Ps 个制表位 |
| `CSI Ps Z` | CBT | 后退 Ps 个制表位 |
| `ESC H` | HTS | 在当前位置设一个制表位 |
| `CSI g` | TBC | 清除当前列制表位 |
| `CSI 3 g` | TBC | 清除**所有**制表位 |
| `CSI 0 g` | TBC | 同 `CSI g` |

默认制表位每 8 列一个（列 1、9、17…）。

---

## 9. 保存 / 恢复 / 复位

| 序列 | 名称 | 作用域 |
|---|---|---|
| `ESC 7` / `ESC 8` | DECSC / DECRC | 光标位置、SGR 属性、字符集、原点模式、自动换行 |
| `CSI s` / `CSI u` | SCOSC / SCORC | 仅光标位置（部分终端等同 DECSC/DECRC） |
| `CSI ? Pm s` | XTSAVE | 保存若干 DEC 私有模式（xterm） |
| `CSI ? Pm r` | XTRESTORE | 恢复若干 DEC 私有模式（xterm） |
| `CSI ! p` | DECSTR | **软复位**：复位模式与属性，但不清屏、不动光标、不清回滚 |
| `ESC c` | RIS | **硬复位**：等价于重新打开终端 |
| `CSI ? 1049 h/l` | — | 备用屏幕（内含保存/恢复光标，见第 10 节） |

`DECSTR` 大致复位：SGR、光标可见、自动换行、原点模式、滚动区域、插入模式、应用光标键、字符集。**它不会**清屏、不会切回主屏、不会清回滚缓冲。

---

## 10. 模式设置（SM/RM、DECSET/DECRST）

### 10.1 标准模式（无 `?` 前缀）

| 序列 | 名称 | 含义 |
|---|---|---|
| `CSI 4 h` / `l` | IRM | 插入模式开 / 关 |
| `CSI 20 h` / `l` | LNM | 自动换行模式：`LF` 同时回车 |
| `CSI 12 h` / `l` | SRM | 本地回显开 / 关（很少用） |
| `CSI 2 h` / `l` | KAM | 键盘锁定（几乎无人实现） |

### 10.2 DEC 私有模式（`CSI ? Pm h` 开 / `CSI ? Pm l` 关）

**最常用的一批**（写 TUI 必背）：

| 模式 | 名称 | 含义 |
|---|---|---|
| `?1` | DECCKM | 应用光标键：方向键改为发 `ESC O A` 而非 `ESC [ A` |
| `?7` | DECAWM | 自动换行（默认开；关了会覆盖行首，慎用） |
| `?6` | DECOM | 原点模式 |
| `?25` | DECTCEM | 显示 / 隐藏光标 |
| `?1004` | — | 上报焦点事件（`CSI I` / `CSI O`） |
| `?2004` | — | **括号粘贴**（bracketed paste），粘贴内容被 `CSI 200~ … CSI 201~` 包裹 |
| `?1049` | — | 备用屏幕 + 保存/恢复光标 + 进入时清屏 |
| `?47` | — | 切换备用屏幕（不清屏，不保存光标） |
| `?1047` | — | 切换备用屏幕（退出时清屏） |
| `?1048` | — | 保存 / 恢复光标（等价 `ESC 7/8`） |
| `?2026` | — | **同步刷新**：`h` 开始缓冲，`l` 一次性提交（消除撕裂） |

**鼠标模式**：

| 模式 | 含义 |
|---|---|
| `?9` | X10 兼容：仅按键按下，`CSI M Cb Cx Cy` |
| `?1000` | 按下 + 释放 |
| `?1002` | 按下 + 释放 + 拖动（button-event） |
| `?1003` | 所有移动（any-event，最耗带宽） |
| `?1005` | UTF-8 坐标编码（已被 `?1006` 取代） |
| `?1006` | **SGR 编码**：`CSI < b ; x ; y M`（按下）/ `m`（释放）—— 现代首选 |
| `?1015` | urxvt 编码 |
| `?1016` | SGR 像素坐标（xterm） |
| `?1007` | 备用屏幕上用滚轮发方向键（alternate scroll） |

**其他值得一提的**：

| 模式 | 含义 |
|---|---|
| `?3` | DECCOLM：80 / 132 列切换（会清屏！） |
| `?5` | DECSCNM：整屏反显 |
| `?12` | 光标闪烁开 / 关 |
| `?40` | 允许 80↔132 切换 |
| `?45` | 反向折返（reverse wraparound） |
| `?66` | 应用小键盘模式（等价 `ESC =`） |
| `?67` | 退格键发 `BS` 而不是 `DEL` |
| `?69` | 左右边距模式（DECLRMM） |
| `?95` | DECCOLM 切换时不清屏 |
| `?1034` / `?1036` / `?1039` | Meta / Alt 键发 `ESC` 前缀的行为 |
| `?1050`–`?1061` | 功能键 / 键盘模拟风格（xterm） |
| `?2027` | 字素簇（grapheme cluster）模式（Kitty） |

### 10.3 模式查询：DECRQM

```text
CSI ? Ps $ p     →  设置：CSI ? Ps ; Pm $ y
                    其中 Pm: 0=未识别 1=已设 2=已复位 3=永久设置 4=永久复位
```

例：查询括号粘贴是否开启 → 发 `CSI ? 2004 $ p`，终端回 `CSI ? 2004 ; 1 $ y`。

---

## 11. SGR：字符属性与颜色

`CSI Pm m` 是最常用的序列。**属性是累积的**，直到被显式复位或 `CSI 0 m` 清空。

### 11.1 基础属性

| 参数 | 含义 | 复位参数 |
|---|---|---|
| `0` | 重置所有属性（含颜色） | — |
| `1` | 粗体 / 高亮 | `22` |
| `2` | 弱化 / 半亮（faint） | `22` |
| `3` | 斜体 | `23` |
| `4` | 下划线 | `24` |
| `4:0`–`4:5` | 下划线样式（见 11.5） | `24` |
| `5` | 慢速闪烁 | `25` |
| `6` | 快速闪烁 | `25` |
| `7` | 反显（前景背景互换） | `27` |
| `8` | 隐藏（前景色 = 背景色） | `28` |
| `9` | 删除线 | `29` |
| `21` | 双下划线（xterm/ECMA-48）；部分终端解释为「取消粗体」 | `24` / `22` |
| `22` | 取消粗体与弱化 | — |
| `23` | 取消斜体 | — |
| `24` | 取消下划线 | — |
| `25` | 取消闪烁 | — |
| `27` | 取消反显 | — |
| `28` | 取消隐藏 | — |
| `29` | 取消删除线 | — |
| `51` | 加框（framed，罕见） | `54` |
| `52` | 加圈（encircled，罕见） | `54` |
| `53` | 上划线（overline，部分终端） | `55` |
| `54` | 取消框 / 圈 | — |
| `55` | 取消上划线 | — |

⚠️ `5`（闪烁）在多数现代终端里被实现成「没有效果」或「加粗」，因为闪烁被视为可访问性问题。不要用它表达重要信息。

### 11.2 16 色

| 前景 | 背景 | 颜色 |
|---|---|---|
| `30` | `40` | 黑 |
| `31` | `41` | 红 |
| `32` | `42` | 绿 |
| `33` | `43` | 黄（实际常显示为棕/橙） |
| `34` | `44` | 蓝 |
| `35` | `45` | 品红 |
| `36` | `46` | 青 |
| `37` | `47` | 白（浅灰） |
| `39` | `49` | **默认**前景 / 背景 |
| `90`–`97` | `100`–`107` | 亮色版本（aixterm 扩展，现为标准做法） |

**重要**：0–15 号颜色由终端主题定义，用户在配置里改过就与「名字」不符。要让颜色符合预期，用 256 色或真彩色并**显式指定 RGB**，或干脆只用默认色 + 粗体/反显。

### 11.3 256 色

```text
CSI 38 ; 5 ; n m      # 前景索引 n
CSI 48 ; 5 ; n m      # 背景索引 n
CSI 38 : 5 : n m      # 等价（子参数写法）
```

调色板分区：

| 索引 | 内容 |
|---|---|
| `0–7` | 标准 8 色 |
| `8–15` | 亮色 8 色 |
| `16–231` | 6×6×6 色立方：`16 + 36r + 6g + b`，`r/g/b ∈ 0..5`，取值表 `[0, 95, 135, 175, 215, 255]` |
| `232–255` | 灰度：`8 + 10n`，`n ∈ 0..23` → 8, 18, …, 238 |

计算示例：`rgb(255,135,0)` → r=5, g=2, b=0 → `16 + 180 + 12 + 0 = 208`。

### 11.4 真彩色（24 位）

两种写法并存：

```text
# 旧式（分号）—— 兼容性最好，事实标准
CSI 38 ; 2 ; R ; G ; B m
CSI 48 ; 2 ; R ; G ; B m

# 标准式（冒号，ITU T.416）—— 带色彩空间标识
CSI 38 : 2 : : R : G : B m        # 色彩空间留空
CSI 38 : 2 : cs : R : G : B m     # cs 通常 0 = sRGB
CSI 38 : 2 : R : G : B m          # 省略色彩空间（歧义写法）
```

⚠️ **歧义警告**：`CSI 38:2:R:G:B` 按标准应解析为 `cs=R`，但许多终端把它当成 `R G B`。所以：

- 想要最大兼容 → 用**分号** `38;2;R;G;B`。
- 想要标准正确 → 用 `38:2::R:G:B`（双冒号占位色彩空间）。
- 不要混用：`38:2;...` 之后又出现冒号是非法写法。

### 11.5 下划线样式与下划线颜色

```text
CSI 4 : n m
```

| n | 样式 |
|---|---|
| `0` | 无 |
| `1` | 直线（普通下划线） |
| `2` | 双线 |
| `3` | 波浪线（curly，拼写检查那种） |
| `4` | 点线 |
| `5` | 虚线 |

下划线颜色（独立于前景/背景）：

```text
CSI 58 ; 5 ; n m           # 256 色索引
CSI 58 ; 2 ; R ; G ; B m   # 真彩色
CSI 59 m                   # 恢复默认下划线颜色
```

支持度：Kitty、WezTerm、foot、Ghostty、iTerm2（较新）、Windows Terminal（部分）、Alacritty（部分）。xterm 长期不支持波浪线。

### 11.6 组合示例

```bash
printf '\033[1;31m错误\033[0m\n'            # 粗体红
printf '\033[38;2;255;135;0m橙色\033[0m\n'  # 真彩色
printf '\033[4:3;58:5:1m波浪下划线\033[0m\n' # 波浪线+红下划线
printf '\033[7m反显\033[27m\n'
```

**最佳实践**：每个着色片段结尾都发 `CSI 0 m`（`\033[0m`），不要依赖「下一个颜色会覆盖」。否则在属性（粗体、下划线）上会串色。

---

## 12. 光标样式（DECSCUSR）

```text
CSI Ps SP q        # 注意：SP 是 0x20，中间字节
```

| Ps | 样式 |
|---|---|
| `0` | 默认（通常 = 闪烁方块） |
| `1` | 闪烁方块 |
| `2` | 稳定方块 |
| `3` | 闪烁下划线 |
| `4` | 稳定下划线 |
| `5` | 闪烁竖线（xterm 扩展） |
| `6` | 稳定竖线（xterm 扩展） |
| `7` | 恢复初始资源（xterm） |

```bash
printf '\033[6 q'   # 竖线光标（Vim 插入模式常见）
printf '\033[2 q'   # 方块光标（普通模式）
```

⚠️ `CSI Ps q` 不带 `SP` 时是 **DECLL**（设置键盘 LED），不是光标样式。别漏空格。

---

## 13. 字符集与 DEC 绘图字符

VT100 用 ISO 2022 的 G0–G3 四组字符集，通过 `SI/SO` 或 `ESC n/o/|/}` 切换 GL/GR。

```text
ESC ( 0      G0 ← DEC 专用图形集（画线）
ESC ( B      G0 ← ASCII
ESC ( A      G0 ← UK
ESC ) 0      G1 ← DEC 图形集
ESC * 0      G2 ← DEC 图形集
ESC + 0      G3 ← DEC 图形集
```

DEC 图形集把字母映射成制表符：

| 字符 | 图形 | 字符 | 图形 |
|---|---|---|---|
| `_` | （空白） | `` ` `` | ◆ |
| `a` | ▒ | `b` | ␉ |
| `c` | ␌ | `d` | ␍ |
| `e` | ␊ | `f` | ° |
| `g` | ± | `h` | ␤ |
| `i` | ␋ | `j` | ┘ |
| `k` | ┐ | `l` | ┌ |
| `m` | └ | `n` | ┼ |
| `o` | ⎺ | `p` | ⎻ |
| `q` | ─ | `r` | ⎼ |
| `s` | ⎽ | `t` | ├ |
| `u` | ┤ | `v` | ┴ |
| `w` | ┬ | `x` | │ |
| `y` | ≤ | `z` | ≥ |
| `{` | π | `\|` | ≠ |
| `}` | £ | `~` | · |

**现代建议**：直接用 UTF-8 的 `─│┌┐└┘├┤┬┴┼`，别用 DEC 字符集。只有在真正的 VT100/串口老设备上才需要。

`ESC % G`（选 UTF-8）与 `ESC % @`（选 Latin-1）在现代终端里基本是空操作，但发送它们可以「叫醒」某些误入非 UTF-8 状态的会话。

---

## 14. 设备查询与上报

查询序列本身不显示，终端通过**输入流**回送应答。TUI 库（ncurses、crossterm、termwiz）靠它们探测能力。

| 发送 | 应答 | 含义 |
|---|---|---|
| `CSI 5 n` | `CSI 0 n` | 设备状态：正常 |
| `CSI 6 n` | `CSI r ; c R` | 光标位置（1 基） |
| `CSI ? 6 n` | `CSI ? r ; c ; p R` | 扩展光标位置（含页号） |
| `CSI c` | `CSI ? 1 ; 2 c` | 主设备属性（DA1）：VT100 + 高级视频 |
| `CSI > c` | `CSI > 41 ; … c` | 次设备属性（DA2） |
| `CSI ? 15 n` | `CSI ? 13 n` / `CSI ? 10 n` | 打印机状态 |
| `CSI > 0 q` | `DCS > \| XTerm(379) ST` | XTVERSION：终端名与版本 |
| `CSI ? u` | `CSI ? flags u` | 查询 Kitty 键盘标志 |
| `DCS $ q Pt ST` | `DCS 1 $ r Pt ST` | DECRQSS：查询某设置的当前值 |

DECRQSS 的 `Pt` 常用值：

| `Pt` | 查询内容 |
|---|---|
| `m` | 当前 SGR |
| `r` | 滚动区域（DECSTBM） |
| `s` | 左右边距（DECSLRM） |
| `SP q` | 光标样式（DECSCUSR） |
| `" p` | DECSCL（一致性级别） |
| `" q` | DECSCA（保护属性） |

**注意**：应答是异步的，且**没有请求 ID**（除 DECRQCRA 有 `Pi`）。解析时必须容忍用户按键与应答交错，且要设超时。不要假设终端一定回应答。

---

## 15. OSC：操作系统命令

形式：`OSC Ps ; Pt ST`，传统上 `BEL`（`0x07`）可代替 `ST`。

| `Ps` | 含义 | 说明 |
|---|---|---|
| `0` | 设置图标名 + 窗口标题 | 最常用 |
| `1` | 设置图标名 | 少见 |
| `2` | 设置窗口标题 | 最常用 |
| `3` | 设置 X 属性 / 工作目录（dtterm） | 少用 |
| `4 ; c ; spec` | 修改调色板第 c 项 | `spec` 可为 `#RRGGBB` 或颜色名 |
| `5 ; c ; spec` | 修改特殊颜色（粗体色等） | |
| `6 ; c ; f` | 启用/禁用特殊颜色 | |
| `7 ; uri` | 报告当前工作目录 | 形如 `file://host/path` |
| `8 ; params ; uri` | **超链接** | 见 18.2 |
| `9 ; text` | 桌面通知（iTerm2/Kitty/WezTerm 等） | |
| `10` | 前景色（可查询 `?`） | |
| `11` | 背景色（可查询 `?`） | |
| `12` | 光标颜色 | |
| `17` | 高亮背景色 | |
| `19` | 高亮前景色 | |
| `22` | 指针形状 | |
| `52 ; Pc ; Pd` | **剪贴板** | 见 18.3 |
| `104` | 重置调色板 | |
| `110` / `111` / `112` | 重置前景 / 背景 / 光标色 | |
| `133 ; …` | **Shell 集成**（提示符标记） | 见 18.4 |
| `1337 ; …` | iTerm2 私有（图像、文件传输等） | 有安全风险 |
| `633 ; …` | VS Code shell 集成 | |
| `777 ; …` | 通知扩展（urxvt/一些终端） | |

**设置标题**：

```bash
printf '\033]0;my-title\007'          # 图标名 + 标题
printf '\033]2;my-title\033\\'        # 仅标题，ST 结尾（更规范）
```

**查询颜色**（用于检测终端是浅色还是深色主题）：

```text
发送：ESC ] 11 ; ? BEL
应答：ESC ] 11 ; rgb:1e1e/1e1e/1e1e BEL
```

**OSC 的坑**：

- 内容里的 `BEL` 会提前结束序列 → 设置标题前要过滤控制字符。
- 内容里的 `ESC` 可能被误认成 `ST` 的开头 → 同理过滤。
- 不是所有终端都实现所有编号；未知编号应静默忽略。

---

## 16. DCS / APC / PM / SOS

这四类是「带字符串载荷」的序列，统一以 `ST` 结束。

### 16.1 DCS（Device Control String）

```text
DCS Pq ; ... ; Pq | Pt ST        # DECUDK：定义用户自定义键
DCS $ q Pt ST                    # DECRQSS：查询状态
DCS + q Pt ST                    # XTGETTCAP：查询 terminfo/termcap
DCS + p Pt ST                    # XTSETTCAP：设置 terminfo 名
DCS Ps $ t Pt ST                 # DECRSPS：恢复呈现状态
DCS > | Pt ST                    # XTVERSION 应答
DCS Pq ; Pq ; Pq q ... ST        # Sixel 图形
DCS tmux ; <escaped> ST          # tmux 穿透（passthrough）
```

**Sixel**：位图图形协议，`DCS Pq ; Pq ; Pq q <data> ST`，其中 `Pq` 是 `Pan;Pad;Ph;Pv`。Kitty/WezTerm/foot 支持，xterm 需编译选项。

**tmux 穿透**：把要透传给外层终端的序列做「`ESC` → `ESC ESC`」转义后包进 `DCS tmux; … ST`。需要外层 `set -g allow-passthrough on`。

### 16.2 APC（Application Program Command）

```text
APC G <kitty graphics payload> ST     # Kitty 图像协议
APC _G ... ST                          # iTerm2 内联图像（旧式写法）
```

### 16.3 PM / SOS

`PM`（Privacy Message）与 `SOS`（Start of String）在现代终端中**基本无实现**，收到后应忽略到 `ST` 为止。它们的存在价值是：解析器必须正确处理「未知字符串序列」，否则会被恶意载荷搞乱状态。

---

## 17. 键盘输入、鼠标、粘贴

终端把按键翻译成字节发给前台程序（除非程序用 raw mode）。这是「转义序列」的另一半。

### 17.1 光标键（受 DECCKM 影响）

| 键 | 普通模式（`?1 l`） | 应用模式（`?1 h`） |
|---|---|---|
| ↑ | `CSI A` | `SS3 A`（`ESC O A`） |
| ↓ | `CSI B` | `SS3 B` |
| → | `CSI C` | `SS3 C` |
| ← | `CSI D` | `SS3 D` |
| Home | `CSI H` 或 `CSI 1 ~` | `SS3 H` |
| End | `CSI F` 或 `CSI 4 ~` | `SS3 F` |

### 17.2 功能键与编辑键

| 键 | 序列 |
|---|---|
| Insert | `CSI 2 ~` |
| Delete | `CSI 3 ~` |
| PageUp | `CSI 5 ~` |
| PageDown | `CSI 6 ~` |
| F1–F4 | `SS3 P` `SS3 Q` `SS3 R` `SS3 S` |
| F5–F12 | `CSI 15~` `17~` `18~` `19~` `20~` `21~` `23~` `24~` |
| BackTab（Shift+Tab） | `CSI Z` |

### 17.3 修饰键

**xterm 规则**：`CSI <base> ; m <final>`，`base` 是该键无修饰时的首个参数（方向键 / Home / End / F1–F4 为 `1`，`~` 类键为其编号如 `15`），其中

```text
m = 1 + (Shift?1:0) + (Alt?2:0) + (Ctrl?4:0) + (Meta?8:0)
```

| 组合 | 序列 |
|---|---|
| Shift+↑ | `CSI 1;2 A` |
| Alt+↑ | `CSI 1;3 A` |
| Ctrl+↑ | `CSI 1;5 A` |
| Ctrl+Shift+↑ | `CSI 1;6 A` |
| Ctrl+Alt+↑ | `CSI 1;7 A` |

对其他键用 `CSI 27 ; m ; code ~`（xterm `modifyOtherKeys`）：

```text
CSI > 4 ; 2 m      # 打开 modifyOtherKeys 级别 2
Ctrl+Shift+A →  CSI 27 ; 6 ; 65 ~
```

### 17.4 Kitty 键盘协议（现代、无歧义）

```text
CSI > flags u            # push 并设置标志
CSI = flags ; mode u     # 设置标志（mode: 1=设,2=或,3=清）
CSI < number u           # pop
CSI ? u                  # 查询 → CSI ? flags u
```

按键上报：`CSI code ; mods[:event] ; text u`，例如 `CSI 97;5u` = Ctrl+a。它解决了传统编码的歧义（无法区分 `Ctrl+I` 与 `Tab` 等）。支持：Kitty、WezTerm、foot、Ghostty；其他终端需探测 `CSI ? u` 是否应答。

### 17.5 鼠标上报

**X10 / 普通编码**（`?9`、`?1000`）：

```text
CSI M Cb Cx Cy
```

三个字节都 `+32` 偏移，最大只能表示到 223 列/行 —— 大屏幕会溢出。

**SGR 编码**（`?1006`，现代首选）：

```text
按下：CSI < Cb ; Cx ; Cy M
释放：CSI < Cb ; Cx ; Cy m
滚轮：Cb 的 bit6 置位（64=上滚, 65=下滚）
```

`Cb` 位定义：

| 位 | 含义 |
|---|---|
| `0–1` | 按钮：0=左 1=中 2=右 3=释放 |
| `2` | Shift |
| `3` | Meta/Alt |
| `4` | Ctrl |
| `5` | 移动（32） |
| `6` | 滚轮（64），配合 bit0 表示方向 |
| `7` | 扩展按钮（128，SGR 专用） |

坐标 **1 基**。

### 17.6 焦点与粘贴

| 序列 | 含义 |
|---|---|
| `CSI I` | 获得焦点（需 `?1004 h`） |
| `CSI O` | 失去焦点 |
| `CSI 200 ~` | 粘贴开始（需 `?2004 h`） |
| `CSI 201 ~` | 粘贴结束 |

括号粘贴解决的是**粘贴内容里含 `\n` 或控制字符**导致命令被立即执行的问题：shell/编辑器看到 `200~` 就进入「原样插入」模式，直到 `201~`。**现代 CLI 程序都应该开启它**。

---

## 18. 现代扩展

### 18.1 同步刷新（Synchronized Output，模式 2026）

```text
CSI ? 2026 h      # 开始：终端缓冲所有绘制
   … 大量输出 …
CSI ? 2026 l      # 结束：一次性提交，避免闪烁/撕裂
```

由 iTerm2 提出，Kitty/WezTerm/foot/Ghostty/Windows Terminal/Alacritty 等支持。对全屏重绘、滚动、动画效果显著。**始终成对发送**，并在异常退出路径也发 `l`（否则终端会一直不刷新）。

### 18.2 超链接（OSC 8）

```text
OSC 8 ; params ; URI ST  显示文本  OSC 8 ; ; ST
```

```bash
printf '\033]8;;https://example.com\033\\示例\033]8;;\033\\\n'
```

- `params` 可含 `id=xxx`，相同 `id` 的链接在部分终端里共享悬停状态。
- 结束用空 URI 的 `OSC 8 ;; ST`。
- 支持：xterm、VTE、Kitty、WezTerm、Alacritty、Windows Terminal、iTerm2、foot。
- **风险**：链接文字可伪装（见第 20 节）。

### 18.3 剪贴板（OSC 52）

```text
OSC 52 ; Pc ; Pd ST
```

- `Pc`：目标，`c` = 剪贴板，`p` = 主选择区，`s` = 选择区，`0–7` = cut buffer。
- `Pd`：**base64 编码**的内容；`?` 表示查询。
- 空 `Pd` 表示清空。

```bash
printf '\033]52;c;%s\033\\' "$(printf 'hello' | base64)"
```

出于安全，多数终端默认**禁用写入**（Kitty 需 `clipboard_control write-clipboard`，xterm 需 `allowWindowOps`，iTerm2 需授权）。不要指望它一定生效。

### 18.4 Shell 集成（OSC 133 / 633 / 7）

用于让终端知道「提示符在哪、命令从哪开始、退出码是多少」，从而实现「跳转到上一条命令」「标记失败命令」「命令块折叠」。

| 序列 | 含义 |
|---|---|
| `OSC 133 ; A ST` | 提示符开始 |
| `OSC 133 ; B ST` | 命令输入开始 |
| `OSC 133 ; C ST` | 命令开始执行 |
| `OSC 133 ; D ; exitcode ST` | 命令结束，带退出码 |
| `OSC 133 ; P ; … ST` | 提示符的语义属性（如 `k=cmd`） |
| `OSC 7 ; file://host/path ST` | 当前工作目录 |
| `OSC 633 ; … ST` | VS Code 变体 |

bash 示例（PROMPT_COMMAND 里发）：

```bash
__osc133() { printf '\033]133;D;%s\007\033]133;A\007' "$?"; }
PROMPT_COMMAND="__osc133; $PROMPT_COMMAND"
PS1='\[\033]133;B\007\]'"$PS1"
```

### 18.5 其他

| 功能 | 序列 | 备注 |
|---|---|---|
| 应用通知 | `OSC 9 ; msg ST` / `OSC 777 ; notify ; title ; body ST` | 支持度参差 |
| 响铃变体 | `CSI Ps SP t` | 音量（VT520，几乎无人实现） |
| 窗口操作 | `CSI Ps ; Ps ; Ps t` | 改大小、最小化、报告像素尺寸等（xterm） |
| 报告像素尺寸 | `CSI 14 t` → `CSI 4 ; h ; w t` | 用于判断 HiDPI |
| 报告字符单元 | `CSI 16 t` → `CSI 6 ; h ; w t` | |
| 报告文本区尺寸 | `CSI 18 t` → `CSI 8 ; rows ; cols t` | 比 `ioctl(TIOCGWINSZ)` 更可靠（某些场景） |

---

## 19. 兼容性速览

> 粗略矩阵，反映 2025–2026 年前后主流实现，**以实测为准**。✓ = 支持，△ = 部分/需配置，— = 不支持。

| 特性 | xterm | VTE | Kitty | WezTerm | Alacritty | Windows Terminal | iTerm2 | foot |
|---|---|---|---|---|---|---|---|---|
| 16 色 / 256 色 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 真彩色 `38;2` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 下划线样式 `4:3` | △ | △ | ✓ | ✓ | △ | △ | ✓ | ✓ |
| 下划线颜色 `58` | — | △ | ✓ | ✓ | △ | △ | △ | ✓ |
| DECSCUSR | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 备用屏幕 1049 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 括号粘贴 2004 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| SGR 鼠标 1006 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 焦点事件 1004 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| OSC 8 超链接 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| OSC 52 剪贴板 | △ | ✓ | △ | ✓ | ✓ | ✓ | △ | ✓ |
| 同步刷新 2026 | △ | △ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Kitty 键盘协议 | — | — | ✓ | ✓ | — | — | — | ✓ |
| Sixel | △ | — | — | ✓ | — | — | — | ✓ |
| Kitty 图形协议 | — | — | ✓ | ✓ | — | — | — | ✓ |
| OSC 133 集成 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

**遇到不支持的序列**：正确行为是**静默忽略**。如果看到 `^[[1;31m` 这样的字面文本，说明程序把转义序列当数据打印了（常见于错误地 `echo` 了变量、或用 `cat` 看了二进制文件）。

---

## 20. 安全：转义序列注入

**核心问题**：终端无法区分「程序想发的指令」与「数据里混进来的指令」。任何进入终端的不可信字节都可能被解释。

| 攻击面 | 说明 |
|---|---|
| **剪贴板劫持**（OSC 52） | 在输出里塞 `OSC 52 ; c ; <base64> ST`，用户下次粘贴时粘贴的是攻击者内容 |
| **链接伪装**（OSC 8） | 显示文字是 `https://bank.com`，实际 URI 是钓鱼站 |
| **标题/提示符伪装**（OSC 0/2） | 把窗口标题改成「sudo: password:」诱导输入密码；或伪造 `user@host` |
| **回写注入**（DCS/DSR） | 诱使终端回送包含转义序列的应答，而应答被前台程序当作输入读取 |
| **解析器漏洞** | Sixel/ReGIS/Kitty 图像、DECRQSS 的解析器历史上多次出现越界/溢出 |
| **日志/终端伪造**（`\r`） | `\r` + 覆盖写可以隐藏真实日志内容（`evil\r[OK]`） |
| **硬复位**（`ESC c`） | 清屏并重置状态，用于销毁现场 |
| **备用屏幕逃逸** | 在 `1049` 里伪装界面，退出后痕迹消失 |

**防御**：

1. **输出不可信内容前过滤控制字符**。最简做法：只保留 `\n`、`\t`，其余 `< 0x20` 和 `0x7F` 全部转义或删除。

   ```bash
   # 删除所有 CSI/OSC 等序列（粗过滤，够用）
   sed -E 's/\x1b\[[0-9;?<=>]*[ -\/]*[@-~]//g; s/\x1b\][^\x07\x1b]*(\x07|\x1b\\)//g' file
   ```

   ```python
   import re, sys
   ESC = r'\x1b'
   CSI = re.compile(ESC + r'\[[0-?]*[ -/]*[@-~]')
   OSC = re.compile(ESC + r'\][^\x07\x1b]*(?:\x07|\x1b\\)')
   def sanitize(s: str) -> str:
       s = OSC.sub('', s)
       s = CSI.sub('', s)
       return ''.join(ch for ch in s if ch >= ' ' or ch in '\n\t')
   ```

2. **查看文件用 `cat -v`**（或 `less -R` 之外的安全模式），把控制字符显示成 `^[`。
3. **限制终端能力**：关掉 `allowWindowOps`、`allowPasteControls`、`clipboard` 写入、Sixel。
4. **程序自身**：不要 `printf` 拼接未转义的用户输入；用 `%s` 而不是把用户输入当格式串；标题设置前先过滤。
5. **SSH/日志管道**：`ssh host cmd | cat -v`；CI 日志渲染器应对控制字符做白名单。
6. **tmux/screen**：`set -g allow-passthrough off`，避免外层终端被内层绕过。

---

## 21. 调试与工具

### 21.1 看见不可见字节

```bash
cat -v file                 # ^[[1;31m 形式
sed -n 'l' file             # 显式显示 \033 等
od -c file | head           # 八进制 + 字符
xxd file | head             # 十六进制
```

```powershell
# Windows PowerShell
Get-Content file -Raw | ForEach-Object { $_ -replace "`e", '<ESC>' }
```

### 21.2 发送测试序列

```bash
printf '\033[1;31mRED\033[0m\n'
printf '\033[?25l'          # 隐藏光标
sleep 2
printf '\033[?25h'          # 显示光标
```

```powershell
# PowerShell 6+ 支持 `e 转义
"`e[1;31mRED`e[0m"
```

### 21.3 查 terminfo

```bash
infocmp -1 xterm-256color     # 展开全部能力
tput civis                    # 隐藏光标（走 terminfo）
tput cup 5 10                 # 定位
tput setaf 1                  # 前景红
tput sgr0                     # 复位
toe -a | head                  # 列出所有终端类型
```

常用能力名 ↔ 序列：

| terminfo | 序列 |
|---|---|
| `clear` | `ESC [ H ESC [ 2 J` |
| `el` | `ESC [ K` |
| `civis` | `ESC [ ? 25 l` |
| `cnorm` | `ESC [ ? 12 l ESC [ ? 25 h` |
| `smcup` | `ESC [ ? 1049 h` |
| `rmcup` | `ESC [ ? 1049 l` |
| `sgr0` | `ESC ( B ESC [ m` |
| `bold` / `smul` / `rev` / `blink` / `dim` | `ESC [ 1 m` 等 |
| `setaf n` / `setab n` | `ESC [ 3n m` / `ESC [ 4n m` |
| `setaf` 256 色 | `ESC [ 38 ; 5 ; n m` |

### 21.4 一致性测试

| 工具 | 用途 |
|---|---|
| `vttest` | VT100/220/420 一致性测试套件 |
| `esctest` | xterm 的转义序列测试框架（Python） |
| `asciinema` | 录制/回放终端会话（含时序） |
| `tmux capture-pane -e -p` | 把窗格内容连同转义序列导出 |
| `kitty +kitten show_key` | 显示按键产生的原始字节 |
| `showkey -a` | Linux 控制台按键字节 |
| `script` | 记录会话原始字节流 |

### 21.5 常见故障

| 现象 | 原因 | 处理 |
|---|---|---|
| 输出 `^[[31m` 字面文本 | 程序把序列当数据打印，或终端不支持、或 `TERM=dumb` | 检查 `TERM`、用 `printf` 而非 `echo` |
| 颜色错乱、属性串到下一行 | 缺少 `CSI 0 m` 复位 | 每个片段结尾复位 |
| 光标不见了 | 之前发了 `?25l` 没恢复 | 发 `?25h`，或 `reset` |
| 全屏程序退出后界面残留 | `?1049` 未成对 | 发 `?1049l`，或 `reset` |
| 键盘方向键变成 `^[[A` | 应用模式未设 / `TERM` 不匹配 | 检查 `?1 h` 与 terminfo |
| 中文/emoji 错位 | 宽字符宽度计算不一致 | 用 `wcwidth`；终端侧 `cjkWidth` |
| 滚动错乱 | `DECSTBM` 未复位 | `CSI r` |

---

## 22. 代码示例

### Bash

```bash
#!/usr/bin/env bash
ESC=$'\033'
printf '%s[1;31m错误%s[0m\n' "$ESC" "$ESC"
printf '%s[?1049h' "$ESC"; trap 'printf "\033[?1049l"' EXIT   # 备用屏幕
```

### Python

```python
import sys, time

ESC = "\x1b"
def sgr(*codes: int) -> str:
    return f"{ESC}[{';'.join(map(str, codes))}m"

sys.stdout.write(sgr(1, 38, 2, 255, 135, 0) + "橙色粗体" + sgr(0) + "\n")

# 进度条：回到行首 + 擦除
for i in range(101):
    sys.stdout.write(f"\r{ESC}[K进度 {i:3d}%")
    sys.stdout.flush()
    time.sleep(0.02)
print()
```

### C

```c
#include <stdio.h>
int main(void) {
    fputs("\x1b[?1049h", stdout);          /* 进入备用屏幕 */
    fputs("\x1b[2J\x1b[H", stdout);        /* 清屏 */
    fputs("\x1b[1;32mHello\x1b[0m\n", stdout);
    fputs("\x1b[?1049l", stdout);          /* 退出备用屏幕 */
    return 0;
}
```

### Node.js

```js
const ESC = "\u001b";
process.stdout.write(`${ESC}[?25l`);                  // 隐藏光标
process.stdout.write(`${ESC}[38;2;0;200;255mCyan${ESC}[0m\n`);
process.stdout.write(`${ESC}[?25h`);                  // 恢复
```

### Go

```go
package main

import "fmt"

func main() {
	fmt.Print("\x1b[?1049h")
	fmt.Print("\x1b[1;33mGo\x1b[0m\n")
	fmt.Print("\x1b[?1049l")
}
```

### Windows / C#

```csharp
using System;
using System.Runtime.InteropServices;

class P {
    [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int n);
    [DllImport("kernel32.dll")] static extern bool GetConsoleMode(IntPtr h, out uint m);
    [DllImport("kernel32.dll")] static extern bool SetConsoleMode(IntPtr h, uint m);

    static void Main() {
        var h = GetStdHandle(-11);
        GetConsoleMode(h, out uint mode);
        SetConsoleMode(h, mode | 0x0004);      // ENABLE_VIRTUAL_TERMINAL_PROCESSING
        Console.Write("\u001b[1;31mRED\u001b[0m\n");
    }
}
```

---

## 23. 速查表

```text
━━━ 基础 ━━━
ESC [ 0 m             重置所有属性
ESC [ 1 m             粗体
ESC [ 4 m             下划线
ESC [ 7 m             反显
ESC [ 31 m            红字
ESC [ 38;5;n m        256 色前景
ESC [ 38;2;r;g;b m    真彩色前景
ESC [ 39 m            默认前景
ESC [ 49 m            默认背景

━━━ 光标 ━━━
ESC [ H / ESC [ 1;1H  左上角
ESC [ r;c H           定位到 (r,c)
ESC [ n A/B/C/D       上/下/右/左 n
ESC [ s  /  ESC [ u   保存 / 恢复
ESC [ ? 25 l / h      隐藏 / 显示光标
ESC [ n SP q          光标样式 n

━━━ 屏幕 ━━━
ESC [ 2 J             清屏
ESC [ 3 J             清回滚缓冲
ESC [ K               擦到行尾
ESC [ n X             擦除 n 个字符
ESC [ n @ / n P       插入 / 删除 n 个字符
ESC [ n L / n M       插入 / 删除 n 行
ESC [ t;b r           设滚动区域
ESC [ ? 1049 h / l    进入 / 退出备用屏幕
ESC [ ? 2026 h / l    同步刷新开始 / 结束

━━━ 模式 ━━━
ESC [ ? 1 h           应用光标键
ESC [ ? 7 l           关闭自动换行
ESC [ ? 6 h           原点模式
ESC [ ? 2004 h        括号粘贴
ESC [ ? 1000 h        鼠标（按下/释放）
ESC [ ? 1006 h        SGR 鼠标编码
ESC [ ? 1004 h        焦点事件

━━━ 字符串 ━━━
ESC ] 0 ; title BEL            设标题
ESC ] 8 ; ; url ST … ESC ] 8 ; ; ST    超链接
ESC ] 52 ; c ; base64 ST       写剪贴板
ESC ] 11 ; ? BEL               查询背景色
ESC ] 133 ; A/B/C/D ST         shell 集成标记
ESC P $ q m ST                 查询 SGR

━━━ 复位 ━━━
ESC [ ! p             软重置（DECSTR）
ESC c                 硬重置（RIS）
reset                 命令级重置
```

---

## 24. 参考资料

- **ECMA-48 / ISO/IEC 6429** — 控制函数的标准语义（语法骨架）
- **xterm ctlseqs** — 事实参考实现文档，覆盖 DEC 与 XT 扩展：<https://invisible-island.net/xterm/ctlseqs/ctlseqs.html>
- **VT510 程序员手册 / DEC STD 070** — DEC 私有序列的原始定义
- **ITU T.416（ISO 8613-6）** — SGR 冒号子参数与真彩色语法
- **Paul Williams, "VT100.net 解析器模型"** — 状态机参考实现：<https://vt100.net/emu/dec_ansi_parser>
- **Kitty 键盘协议**：<https://sw.kovidgoyal.net/kitty/keyboard-protocol/>
- **Kitty 图形协议**：<https://sw.kovidgoyal.net/kitty/graphics-protocol/>
- **Sixel**：<https://www.vt100.net/docs/vt3xx-gp/chapter14.html>
- **同步刷新（2026）**：<https://gist.github.com/christianparpart/d8a62cc1ab659194337d73e399004036>
- **terminfo(5)**：`man 5 terminfo`
- **`vttest`**：<https://invisible-island.net/vttest/>

---

*本文档为工程参考手册，行为以目标终端的实际实现为准。遇到分歧时，优先保证「不支持的序列被静默忽略」和「属性成对复位」两条工程原则。*

---

## 相关笔记

- [[ANSI 转义序列]]：入门版，偏 Python / TUI 实践与常见坑。
- [[TUI 笔记]]：全屏终端界面的整体概念与库对比。
