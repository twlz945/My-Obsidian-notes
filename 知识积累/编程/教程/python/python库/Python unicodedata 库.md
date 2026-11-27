---
title: Python unicodedata 库
date: 2026-11-19
tags:
  - Python
  - 标准库
  - Unicode
  - 文本处理
  - 教程
aliases:
  - Python unicodedata 模块
  - unicodedata 标准库
  - Unicode 数据库
related:
  - "[[Python 字符串]]"
  - "[[Python 文件读写]]"
  - "[[Python json 库]]"
  - "[[Python msvcrt 库]]"
  - "[[Python time 库]]"
---

# Python unicodedata 库

`unicodedata` 是标准库里的 **Unicode 字符数据库（UCD）查询接口**。它不编码、不解码、不做大小写转换，只回答关于「单个字符」的问题：这个字符叫什么、属于哪一类、数值是多少、显示多宽、由什么分解而来、在双向文本里怎么排。

把它理解成**字符说明书**：`str` 方法负责「怎么处理文本」，`unicodedata` 负责「这个字符到底是什么」。本笔记基于 CPython 3.14 实测（`unidata_version == "16.0.0"`）。

它的数据直接编译自 Unicode 官方 UCD，所以**结果跟着 Python 版本走**：同一个码点在不同 Python 版本里可能有不同属性（新版本分配了新字符）。需要可复现的场景要记录 `unidata_version`。

## 核心要点

- 所有查询函数**只接受长度为 1 的字符串**，传入 `"ab"` 或 emoji 序列会直接 `TypeError`。
- 三个数值函数容易混：`decimal`（只认 0–9 形态）、`digit`（含上标 ²）、`numeric`（含 ½、Ⅻ、一）。
- `normalize` 只有 `NFC` / `NFD` / `NFKC` / `NFKD` 四种形式，**区分大小写**，不做 casefold，也不处理「长得像」的字符。
- `lookup()` 可能返回**多个字符**（named sequence），而 `name()` 只接受单个字符。
- `east_asian_width` 有 6 个值，`A`（Ambiguous）的宽度取决于终端与 locale。
- `Cn`（未分配）不等于非法字符；`Cf` 里藏着零宽字符和双向控制符，是安全审查重点。
- `unicodedata.ucd_3_2_0` 是给 IDNA 等旧协议用的 3.2 版数据库。

## 函数总览

| 函数 | 返回 | 无值时 | 用途 |
| ---- | ---- | ---- | ---- |
| `lookup(name)` | `str`（可能多字符） | `KeyError` | 按名字查字符 |
| `name(chr, default=None)` | `str` | `ValueError` | 查字符名 |
| `decimal(chr, default=None)` | `int` | `ValueError` | 十进制数字值 |
| `digit(chr, default=None)` | `int` | `ValueError` | 数字值（含上标） |
| `numeric(chr, default=None)` | `float` | `ValueError` | 数值（含分数、汉字） |
| `category(chr)` | 两字母 `str` | — | 通用类别 |
| `combining(chr)` | `int` | `0` | 组合类权重 |
| `bidirectional(chr)` | `str`，可能 `""` | `""` | 双向类 |
| `east_asian_width(chr)` | 单字母 `str` | — | 东亚宽度 |
| `mirrored(chr)` | `0` / `1` | — | 是否镜像字符 |
| `decomposition(chr)` | `str`，可能 `""` | `""` | 分解映射 |
| `normalize(form, s)` | `str` | `ValueError` / `TypeError` | 归一化整串 |
| `is_normalized(form, s)` | `bool` | `ValueError` / `TypeError` | 是否已是该形式 |

`is_normalized()` 是 3.8 新增。除 `normalize` / `is_normalized` 外，**其余全部是单字符函数**：

```python
>>> unicodedata.category("ab")
TypeError: category(): argument must be a unicode character, not a string of length 2
```

## 最小示例

```python
import unicodedata as u

u.name("é")                                  # 'LATIN SMALL LETTER E WITH ACUTE'
u.lookup("LATIN SMALL LETTER E WITH ACUTE")  # 'é'
u.category("一")                             # 'Lo'
u.east_asian_width("一")                     # 'W'
u.numeric("½")                               # 0.5
u.normalize("NFC", "e\u0301") == "é"         # True
```

## 通用类别：`category`

两字母代码：第一位是**大类**，第二位是**子类**。这是最常用的属性查询入口。

| 代码 | 含义 | 例子 |
| ---- | ---- | ---- |
| `Lu` / `Ll` / `Lt` | 大写 / 小写 / 标题字母 | `A` / `a` / `ǅ` |
| `Lm` / `Lo` | 修饰字母 / 其他字母 | `ʰ` / `一`、`あ` |
| `Mn` / `Mc` / `Me` | 非间距 / 间距 / 包围组合符号 | `U+0301` / `U+0903` / `U+20DD` |
| `Nd` | 十进制数字 | `0`、`٣` |
| `Nl` / `No` | 字母数字 / 其他数字 | `Ⅻ` / `½`、`①` |
| `Pc` / `Pd` / `Ps` / `Pe` | 连接 / 破折 / 开 / 闭标点 | `_` / `-` / `(` / `)` |
| `Pi` / `Pf` / `Po` | 前引号 / 后引号 / 其他标点 | `“` / `”` / `!` |
| `Sm` / `Sc` / `Sk` / `So` | 数学 / 货币 / 修饰 / 其他符号 | `+` / `$` / `^` / `😀` |
| `Zs` / `Zl` / `Zp` | 空格 / 行分隔 / 段分隔 | ` `、`　` / `U+2028` / `U+2029` |
| `Cc` | 控制字符 | `\t`、`\n`、`\x00` |
| `Cf` | 格式字符（不可见） | 零宽空格 `U+200B`、`U+FE0F`、RLO `U+202E` |
| `Cs` / `Co` | 代理项 / 私用区 | `\ud800` / `U+E000` |
| `Cn` | **未分配** | `U+0378` |

几个实用判断：

```python
def is_control(ch: str) -> bool:
    return u.category(ch) == "Cc"

def is_emoji_like(ch: str) -> bool:
    return u.category(ch) == "So"
```

> [!note] `Cn` 不是「非法」
> `Cn` 只表示当前 Unicode 版本还没给它分配含义。新版本发布后它可能变成正经字符。反过来，Python 允许字符串里存在**孤立代理项**（`"\ud800"`），`category` 返回 `Cs`，`normalize` 也照样放行，但一旦 `encode("utf-8")` 就会抛 `UnicodeEncodeError`。

## 三个数值函数

| 字符 | `decimal` | `digit` | `numeric` |
| ---- | ---- | ---- | ---- |
| `"0"` | `0` | `0` | `0.0` |
| `"٣"`（阿拉伯-印度数字 3） | `3` | `3` | `3.0` |
| `"²"`（上标 2） | `ValueError` | `2` | `2.0` |
| `"½"` | `ValueError` | `ValueError` | `0.5` |
| `"Ⅻ"`（罗马数字 12） | `ValueError` | `ValueError` | `12.0` |
| `"一"`（汉字 1） | `ValueError` | `ValueError` | `1.0` |
| `"⅓"` | `ValueError` | `ValueError` | `0.3333…` |

规律：`decimal` 覆盖 `Nd`，`digit` 多覆盖上标/下标等有「数字值」的字符，`numeric` 最宽，连分数、罗马数字、汉字数字都算。

```python
def to_number(ch: str) -> float:
    """把单个数字字符转成数值；不是数字就抛 ValueError。"""
    for f in (u.decimal, u.digit, u.numeric):
        try:
            return float(f(ch))
        except ValueError:
            continue
    raise ValueError(f"不是数字字符: {ch!r}")
```

> [!warning] 「看起来是 1」不代表是 1
> `"一"`、`"①"`、`"½"` 在人类看来都是数字，但 `decimal()` 只认 `Nd`。做表单校验时不要用 `str.isdigit()` 一把梭——`isdigit()` 对 `"²"` 返回真，`float()` 却解析不了。

## 组合类：`combining`

返回**规范组合类**（Canonical Combining Class，ccc）的整数值：`0` 表示「起始字符」，非 0 表示「附加符号」，数字越大越靠后。

```python
>>> u.combining("a")          # 0，起始字符
>>> u.combining("\u0301")     # 230，锐音符（above）
>>> u.combining("\u0327")     # 202，下加符（below）
```

作用在归一化里：NFD/NFC 会对连续的组合符号按 ccc 做**稳定排序**，所以「先重音后下加符」会被重排成规范顺序：

```python
>>> [hex(ord(c)) for c in u.normalize("NFD", "a\u0301\u0327")]
['0x61', '0x327', '0x301']     # a + 下加符(202) + 锐音符(230)，顺序被纠正
```

这也是「组合顺序不同、看起来一样、`==` 为假」的根源。判断一个字符是不是「附加在别人身上的符号」，看 `combining(c) != 0` 或 `category(c).startswith("M")` 比手写码点表靠谱。

## 东亚宽度：`east_asian_width`

| 值 | 含义 | 例子 | 终端列宽 |
| -- | ---- | ---- | ---- |
| `F` | Fullwidth 全角 | `Ａ`、`　`（U+3000） | 2 |
| `H` | Halfwidth 半角 | `ｱ`、`ﾊﾝｶｸ` | 1 |
| `W` | Wide 宽 | `一`、`あ`、`😀` | 2 |
| `Na` | Narrow 窄 | ASCII 字母数字 | 1 |
| `N` | Neutral 中性 | 大多数未特别指定的符号 | 1 |
| `A` | **Ambiguous 歧义** | `½`、`é` 的组合重音、部分希腊字母 | 1 或 2 |

`A` 是坑：在东亚语言环境下按 2 列算，在英文环境下按 1 列算，具体由终端决定。做对齐时通常按 1 算，并在中文环境额外处理。

```python
def cell_width(s: str) -> int:
    """估算终端显示宽度（不处理 emoji 的 ZWJ 序列）。"""
    return sum(2 if u.east_asian_width(c) in ("W", "F") else 1 for c in s)
```

> [!warning] 宽度 ≠ 码点数
> `len("👨‍👩‍👧‍👦")` 是 **7**（4 个 emoji + 3 个 ZWJ），`cell_width` 会算成 8 列，而实际显示只有 2 列。因为 ZWJ 是 `Cf`、`east_asian_width` 为 `N`，被当成 0 宽或 1 宽都不对。精确排版请用 `wcwidth` 库或按字素簇（grapheme cluster）切分，`unicodedata` 只给字符级信息。

## 归一化：`normalize`

### 为什么需要

同一个 `é` 有两种写法，`==` 比较为假：

```python
a = "é"          # U+00E9，单码点
b = "e\u0301"    # U+0065 + U+0301，e + 组合锐音符
a == b           # False
u.normalize("NFC", a) == u.normalize("NFC", b)   # True
```

用户输入、文件名、搜索关键词、数据库主键，只要涉及跨来源比较，就必须先统一。

### 四种形式

| 形式 | 全称 | 做什么 | 例子 |
| ---- | ---- | ---- | ---- |
| `NFC` | Canonical Composition | 先规范分解、再合成 | `e`+`◌́` → `é` |
| `NFD` | Canonical Decomposition | 拆成基字符 + 组合符号 | `é` → `e`+`◌́`；`한` → 3 个字母 |
| `NFKC` | Compatibility Composition | 兼容分解 + 合成 | `①`→`1`、`Ａ`→`A`、`ﬁ`→`fi`、`㍿`→`株式会社`、`　`→空格 |
| `NFKD` | Compatibility Decomposition | 兼容分解，不合成 | `½`→`1⁄2`、`㎏`→`kg` |

- 形式名**区分大小写**：传 `"nfc"` 抛 `ValueError`。
- 归一化**幂等**：`NFC(NFC(x)) == NFC(x)`。
- 第二参数必须是 `str`，传 `bytes` 抛 `TypeError`。

### 该选哪个

- **存储与一般比较用 `NFC`**：字符数最少、人类可读，是 W3C 推荐形式。
- **兼容性对齐用 `NFKC`/`NFKD`**：全角转半角、圈号数字、连字，但注意它会把「不同字符」压成同一个——`①`、`⑴`、`1` 会全部变 `1`。
- **不要用 NFKC 做安全比较**：它不处理同形异码（西里尔 `а` 与拉丁 `a`），需要 confusables 数据。
- **标识符按 NFKC**：PEP 3131 规定 Python 标识符按 NFKC 归一化，所以全角 `ｖａｒ` 与 `var` 是同一个名字；但这也意味着全角写法能伪装成 ASCII。

> [!warning] NFKC 会改变长度
> `ﬁ` 归一化后变成 `fi`，长度 1 → 2。如果先算好字符串下标再 NFKC，偏移量会错位；报错位置、`str.find` 结果都可能指向错误位置。需要精确下标时，用 `is_normalized()` 判断、避免对已归一化文本重复处理，或按下标映射表处理。

### 比较与搜索

```python
def same_text(a: str, b: str) -> bool:
    """文本相等比较：统一成 NFC 再比。"""
    return u.normalize("NFC", a) == u.normalize("NFC", b)

def search_key(s: str) -> str:
    """搜索/去重键：NFKC 收敛兼容字符，再 casefold 忽略大小写。"""
    return u.normalize("NFKC", s).casefold()
```

> [!tip] 只在边界归一化
> 不要在每个函数里都 `normalize`。约定「入口处归一化一次（存储 NFC），出口按需」最省事。`normalize` 对已归一化的字符串仍有扫描开销，热路径可先用 `is_normalized()` 短路。

### 分解串：`decomposition`

返回「一级分解映射」，可能是空串、纯码点（规范分解），或带 `<标签>` 的兼容分解：

```python
u.decomposition("é")    # '0065 0301'          规范分解
u.decomposition("ﬁ")    # '<compat> 0066 0069' 兼容分解（fi）
u.decomposition("①")    # '<circle> 0031'
u.decomposition("½")    # '<fraction> 0031 2044 0034'
u.decomposition("㎏")   # '<square> 006B 0067'
u.decomposition("A")    # ''                   无分解
```

标签说明这是哪种兼容性：`<compat>`、`<circle>`、`<fraction>`、`<wide>`、`<narrow>`、`<font>`、`<super>`、`<sub>`、`<square>`、`<vertical>`、`<noBreak>`、`<initial>` / `<medial>` / `<final>` / `<isolated>`。

**有标签 ≠ 规范等价**：`ﬁ` 和 `fi` 视觉相似但码点不同，`NFC` 不会合并它们，只有 `NFKC` / `NFKD` 会。想要「完整展开」直接用 `NFKD`，不要自己递归解析 `decomposition()`。

## 名字：`lookup` 与 `name`

```python
>>> u.lookup("LEFT CURLY BRACKET")         # '{'
>>> u.lookup("MIDDLE DOT") == "\N{MIDDLE DOT}"   # True
>>> u.name("½")                            # 'VULGAR FRACTION ONE HALF'
>>> u.name("\uFFFF", "fallback")           # 'fallback'
```

- `lookup` 找不到抛 `KeyError`；`name` 找不到抛 `ValueError`，可用第二个参数兜底（3.3+）。
- 3.3 起 `lookup` 支持**名字别名**与**命名序列**（named sequences），所以返回值**可能是多个字符**：

```python
>>> seq = u.lookup("KEYCAP DIGIT ONE")
>>> seq, len(seq)
('1️⃣', 3)                          # '1' + VS16 + U+20E3
>>> u.name(seq)
TypeError: name(): argument 1 must be a unicode character, not a string of length 3
```

- `lookup` 实测**大小写不敏感**（文档未承诺，别写成依赖）。
- 只有部分字符有「真名」：汉字、谚文音节有算法生成名（`CJK UNIFIED IDEOGRAPH-4E00`、`HANGUL SYLLABLE GA`），未分配码点 `U+0378` 没有名字。
- 用途：调试不可见字符、把码点转成人能读的日志、教学演示。

## 双向类与安全：`bidirectional` / `mirrored`

`bidirectional()` 返回 UBA（Unicode 双向算法）的双向类：

| 值 | 含义 | 例子 |
| -- | ---- | ---- |
| `L` | 从左到右 | 拉丁、汉字 |
| `R` / `AL` | 从右到左 / 阿拉伯字母 | 希伯来 `א` / 阿拉伯 `ا` |
| `EN` / `AN` | 欧洲数字 / 阿拉伯数字 | `1` / `٣` |
| `ON` | 其他中性 | 大多数符号、`😀` |
| `NSM` | 非间距标记 | 组合符号、`U+FE0F` |
| `BN` | 边界中性 | 控制符、零宽字符 |
| `WS` | 空白 | 空格 |
| `RLO` / `LRO` 等 | 显式方向覆盖 | `U+202E` / `U+202D` |

`mirrored()` 返回 `1` 表示该字符在 RTL 文本中应镜像显示（括号、尖括号等）：

```python
>>> u.mirrored(">")     # 1
>>> u.mirrored("a")     # 0
```

> [!warning] 双向控制符是源码投毒手段
> `U+202E`（类别 `Cf`、双向类 `RLO`）能让后面的文本反向显示，把恶意代码伪装成注释，即 Trojan Source（CVE-2021-42574）。审查不可信文本（源码、PR、简历）时，先剥掉双向控制符：
> ```python
> BIDI_CONTROLS = {"\u202a", "\u202b", "\u202c", "\u202d", "\u202e",
>                  "\u2066", "\u2067", "\u2068", "\u2069"}
>
> def strip_bidi(s: str) -> str:
>     return "".join(c for c in s if c not in BIDI_CONTROLS)
> ```

## 常用片段

### 清理控制字符（保留换行与制表）

```python
KEEP = {"\n", "\r", "\t"}

def strip_controls(s: str) -> str:
    return "".join(c for c in s if c in KEEP or u.category(c) != "Cc")
```

### 全角转半角

```python
def to_halfwidth(s: str) -> str:
    return u.normalize("NFKC", s)   # ＡＢＣ１２３ → ABC123
```

注意方向**因字符而异**：拉丁全角 `Ａ` 会变半角 `A`，但半角片假名 `ｱ` 会被 NFKC 变成**全角** `ア`（Unicode 认为全角片假名才是「规范形式」）。

### 显示宽度与不可见字符说明

```python
def cell_width(s: str) -> int:
    return sum(2 if u.east_asian_width(c) in ("W", "F") else 1 for c in s)

def describe(s: str) -> None:
    for c in s:
        print(f"U+{ord(c):04X}  {u.category(c):2}  {u.east_asian_width(c)}  {u.name(c, '<unnamed>')}")

describe("a\u200b一")
# U+0061  Ll  Na  LATIN SMALL LETTER A
# U+200B  Cf  N   ZERO WIDTH SPACE
# U+4E00  Lo  W   CJK UNIFIED IDEOGRAPH-4E00
```

### 归一化去重

```python
def dedupe(words: list[str]) -> list[str]:
    seen: dict[str, str] = {}
    for w in words:
        seen.setdefault(search_key(w), w)
    return list(seen.values())
```

## 常见陷阱

1. **单字符限制**：`category("ab")`、`name("1️⃣")` 直接 `TypeError`，要逐字符遍历或先取 `s[0]`。
2. **归一只做「等价」**：`ñ` 与 `n`、西里尔 `а` 与拉丁 `a` 都不会被合并，需要 confusables。
3. **归一只做「码点」**：`normalize` 不管大小写，`"Straße"` 与 `"STRASSE"` 仍需 `casefold()`。
4. **`NFKC` 改长度**：`ﬁ`→`fi`，上下标、圈号、连字都会变长或变短，下标偏移失效。
5. **`len()` 是码点数**：组合符号、emoji、ZWJ 序列都会让 `len()` 与「肉眼字符数」不符。
6. **`decimal` / `digit` / `numeric` 混用**：`"½"` 只有 `numeric` 认，`"²"` 只有 `digit`/`numeric` 认。
7. **把 `Cn` 当非法字符**：它只是「本版本未分配」，新版本可能变成真字符。
8. **`lookup` 结果当单字符**：命名序列返回多字符，`name()` 会拒绝。
9. **`UCD` 版本漂移**：3.12 是 15.0.0、3.13 是 15.1.0、3.14 是 16.0.0，跨版本属性可能变。
10. **孤立代理项**：`"\ud800"` 能过 `normalize`，但 `encode("utf-8")` 抛 `UnicodeEncodeError`。
11. **`A` 宽度依赖上下文**：同一个 `½` 在中文终端按 2 列算，在英文终端按 1 列。
12. **文件名跨平台**：macOS 的 HFS+ 把文件名存成 NFD，从 Linux 拖过来的 NFC 名字看着一样却不相等，比较前先归一并注意大小写敏感性。
13. **`east_asian_width` 不是字形宽度**：它给的是终端列宽类别，不是字体排版里的字形宽度。

## 与其他工具的分工

| 任务 | 工具 |
| ---- | ---- |
| 编码 / 解码 | `str.encode()` / `bytes.decode()` |
| 大小写、`casefold` | `str.upper()` / `str.lower()` / `str.casefold()` |
| 字符属性、名称、数值、宽度 | `unicodedata` |
| 归一化 | `unicodedata.normalize()` |
| 字素簇切分（emoji、组合字符） | `regex` 的 `\X` 或 `grapheme` 库 |
| 终端显示宽度 | `wcwidth` / `wcswidth` |
| 同形异码检测 | `confusables` 库 / 自建映射 |
| 标识符合法性 | `str.isidentifier()`（PEP 3131） |
| 排序与排序规则 | `locale.strxfrm()` / PyICU |

## 版本与数据

| Python | UCD 版本 | 备注 |
| ------ | ------- | ---- |
| 3.8 | 12.1.0 | 新增 `is_normalized()` |
| 3.12 | 15.0.0 | — |
| 3.13 | 15.1.0 | — |
| 3.14 | 16.0.0 | 本笔记实测版本 |

- `unicodedata.unidata_version` 返回当前 UCD 版本字符串。
- `unicodedata.ucd_3_2_0` 是一个「模块的镜像对象」，方法相同但数据固定为 3.2 版，供 IDNA / stringprep 这类**要求固定旧版本**的协议使用。
- `category` / `name` 等函数从早期版本起就只接受长度为 1 的 `str`；3.3 起 `lookup` 可能返回多字符，两者串起来用时容易误判。

## 最佳实践

- **入口归一化**：用户输入、文件内容、网络数据进来先 `NFC`，存库保持 `NFC`。
- **比较先归一**：任何「看起来一样却不等」的问题，先怀疑组合字符。
- **搜索键 = NFKC + casefold**，并接受它带来的字符合并。
- **不要手写字符表**：用 `category()` / `east_asian_width()` 判断，避免漏掉新版本字符。
- **宽度交给 `wcwidth`**：`unicodedata` 只到字符级，处理 emoji 一定要字素簇。
- **记录 `unidata_version`**：做文本相关的快照、测试、缓存键时，把版本带上。
- **安全场景剥控制符**：`Cc` + `Cf`（尤其双向控制符）是审查不可信文本的第一步。

## 参考来源

- [unicodedata — Unicode Database（Python 3.14 官方文档）](https://docs.python.org/3.14/library/unicodedata.html)
- [UAX #44: Unicode Character Database](https://www.unicode.org/reports/tr44/)
- [UAX #15: Unicode Normalization Forms](https://www.unicode.org/reports/tr15/)
- [UAX #11: East Asian Width](https://www.unicode.org/reports/tr11/)
- [Unicode 16.0.0 Character Database](https://www.unicode.org/Public/16.0.0/ucd/)
- [Unicode HOWTO（Python 官方）](https://docs.python.org/3/howto/unicode.html)
- [PEP 3131 — Supporting Non-ASCII Identifiers](https://peps.python.org/pep-3131/)

## 相关笔记

- [[Python 字符串]] — `str` 基础、`encode`/`decode` 与 NFC 速查
- [[Python 文件读写]] — 显式 `encoding` 与 `UnicodeDecodeError` 处理
- [[Python json 库]] — `ensure_ascii` 与 `\uXXXX` 转义
- [[Python msvcrt 库]] — `getwch()` 读取宽字符
- [[Python time 库]] — 同一套「标准库深挖」笔记的写法参考
