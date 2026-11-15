---
title: Python time 库
date: 2026-11-15
tags:
  - Python
  - 标准库
  - 时间
  - 教程
aliases:
  - Python time 模块
  - time 标准库
  - Python 时间戳
related:
  - "[[Python dataclasses 库]]"
  - "[[Python json 库]]"
  - "[[Python 文件读写]]"
  - "[[Python msvcrt 库]]"
  - "[[固定步长循环]]"
  - "[[用 Python 搭建复杂项目]]"
---

# Python time 库

`time` 是 Python 最底层的标准库之一，负责两件事：**表示某个瞬间**（时间戳、`struct_time`）和**测量时间流逝**（计时、睡眠）。它直接封装平台 C 库的同名函数（`localtime()`、`strftime()`、`clock_gettime()` 等），所以行为带平台差异，文档里反复出现「platform-dependent」。

定位可以用一句话概括：**`time` 管「瞬间」和「计时」，`datetime` 管「日历」和「时区」**。需要日期加减、时区换算、ISO 8601 解析时应该用 `datetime` + `zoneinfo`；需要时间戳、单调计时、`sleep` 时才用 `time`。三者读的是同一套系统时钟，`datetime.now()` 与 `time.time()` 拿的是同一个墙钟。

本笔记基于 CPython 3.14 实测验证，涉及 3.15 的行为变化单独标注。

## 核心要点

- 三种时钟别混用：**墙钟**（`time`）、**单调时钟**（`monotonic` / `perf_counter`）、**CPU 时钟**（`process_time` / `thread_time`）。
- **测耗时永远不要用 `time.time()`**：它会被 NTP 校时和手动改时间影响，可能倒退。
- 高精度场景用 `*_ns()` 整数版本，避免 `float` 在 1.7e9 量级的精度损失。
- `struct_time` 是 9 个整数的具名元组，**月份 1–12**（与 C 的 0–11 不同），`tm_wday` 周一为 0。
- `strftime` / `strptime` 依赖平台 C 库与 locale；跨平台只用文档列出的指令，别用 `%s`、`%F`。
- `time` 只有「本地时区」和「UTC」两个视角，没有时区对象；历史时间和跨时区换算交给 `zoneinfo`。
- 32 位平台上 `time_t` 溢出点仍在 2038 年。

## 最小示例

```python
import time

# 1) 当前时间戳（秒，float）
ts = time.time()
print(ts)                              # 1794737253.0058153

# 2) 转成可读的本地时间
lt = time.localtime(ts)
print(lt)                              # time.struct_time(tm_year=2026, tm_mon=11, ...)
print(time.strftime("%Y-%m-%d %H:%M:%S", lt))   # 2026-11-15 18:07:32

# 3) 测一段代码耗时（正确做法）
start = time.perf_counter()
sum(range(1_000_000))
elapsed = time.perf_counter() - start
print(f"{elapsed * 1000:.3f} ms")

# 4) 睡眠
time.sleep(0.5)
```

## 时钟：先选对函数

| 函数 | 时钟类型 | 会跳变 | 包含 `sleep` | 典型用途 |
| ---- | ---- | ---- | ---- | ---- |
| `time()` / `time_ns()` | 墙钟（Unix time） | 会 | — | 记录时间戳、存库、日志 |
| `monotonic()` / `monotonic_ns()` | 单调 | 不会 | 是 | 测间隔、超时判定 |
| `perf_counter()` / `perf_counter_ns()` | 单调 + 最高分辨率 | 不会 | 是 | 基准测试、性能计时 |
| `process_time()` / `process_time_ns()` | 进程 CPU 时间 | 不会 | 否 | CPU 占用分析 |
| `thread_time()` / `thread_time_ns()` | 线程 CPU 时间 | 不会 | 否 | 单线程 CPU 分析 |

几个容易搞混的点：

- **`monotonic` vs `perf_counter`**：两者都单调，但 `perf_counter` 保证是「最高可用分辨率」。3.13 起二者在 CPython 上使用同一个时钟（Windows 都是 `QueryPerformanceCounter()`），历史上前者分辨率可能较低。测短代码块直接用 `perf_counter_ns()`。
- **`perf_counter` 包含睡眠时间**，所以它测的是「墙上过去了多久」，不是「CPU 忙了多久」。要排除睡眠用 `process_time`。
- **`*_ns()` 返回整数纳秒**。`time_ns()` 在 2026 年约 1.79e18，`float` 只能精确表示到约 2^53，所以 `time.time()` 在当前纪元的分辨率实际只有几百纳秒，`time_ns()` 无损。

> [!warning] 用 `time.time()` 测耗时是经典 bug
> 系统校时（NTP）或用户改时间时，`time.time()` 会向前或向后跳，测出的耗时会变成负数或天文数字。凡是「两个时间点相减」的场景，一律用 `perf_counter()` 或 `monotonic()`。

`get_clock_info()` 可以查看当前平台某个时钟的实现、分辨率、是否可调：

```python
>>> time.get_clock_info("perf_counter")
namespace(implementation='QueryPerformanceCounter()', monotonic=True,
          adjustable=False, resolution=1e-07)
```

> [!tip] 基准测试的正确写法
> 用 `timeit` 而不是手写 `perf_counter` 循环：`python -m timeit -s "import x" "x.f()"`。`timeit` 会处理预热、多次采样和最小值统计。

## 时间戳与 `struct_time`

转换关系（官方文档的对照表，补了字符串两向）：

| 从 | 到 | 用 |
| --- | --- | --- |
| 秒（时间戳） | UTC 的 `struct_time` | `gmtime()` |
| 秒（时间戳） | 本地时间的 `struct_time` | `localtime()` |
| UTC 的 `struct_time` | 秒 | `calendar.timegm()` |
| 本地时间的 `struct_time` | 秒 | `mktime()` |
| `struct_time` | 字符串 | `strftime()` / `asctime()` / `ctime()` |
| 字符串 | `struct_time` | `strptime()` |

`struct_time` 是具名元组，既能按下标访问也能按属性访问：

| 下标 | 属性 | 含义 | 范围 |
| --- | --- | --- | --- |
| 0 | `tm_year` | 年 | 如 2026 |
| 1 | `tm_mon` | 月 | 1–12 |
| 2 | `tm_mday` | 日 | 1–31 |
| 3 | `tm_hour` | 时 | 0–23 |
| 4 | `tm_min` | 分 | 0–59 |
| 5 | `tm_sec` | 秒 | 0–61（60/61 为闰秒预留） |
| 6 | `tm_wday` | 星期 | 0–6，**周一为 0** |
| 7 | `tm_yday` | 一年中第几天 | 1–366 |
| 8 | `tm_isdst` | 夏令时标志 | 0 / 1 / -1（未知） |
| — | `tm_zone` | 时区缩写 | 仅属性，不在序列里 |
| — | `tm_gmtoff` | 相对 UTC 的偏移秒数 | 仅属性，不在序列里 |

```python
>>> st = time.gmtime(0)
>>> st
time.struct_time(tm_year=1970, tm_mon=1, tm_mday=1, tm_hour=0, tm_min=0,
                 tm_sec=0, tm_wday=3, tm_yday=1, tm_isdst=0)
>>> st.tm_year, st[0]      # 1970 1970
>>> st[:3]                 # (1970, 1, 1) 切片返回普通 tuple
```

> [!note] `n_fields` 与序列长度
> `struct_time.n_fields == 11`、`n_sequence_fields == 9`、`n_unnamed_fields == 0`。也就是说 `tm_zone` / `tm_gmtoff` 只能用属性访问，解包成 9 个变量是安全的，写成 11 个会 `ValueError`。

关键行为：

- `gmtime()` / `localtime()` **直接丢弃小数秒**：`time.gmtime(1.9).tm_sec == 1`。要保留毫秒必须自己用 `ts % 1` 或改用 `datetime`。
- `mktime()` 接收**本地时间**的 9 元组，`tm_isdst` 未知时填 `-1` 让 C 库推断；返回 `float`。
- 超出平台 `time_t` 范围会抛 `OverflowError` 或 `OSError`，通常被限制在 1970–2038。
- `struct_time` 不支持日期加减，`st + timedelta` 会抛 `TypeError`——日期运算交给 `datetime`。

## 格式化：`strftime`

`strftime(format[, time_tuple])`，省略 `time_tuple` 时用 `localtime()` 的当前时间。

| 指令 | 含义 | 备注 |
| --- | --- | --- |
| `%Y` / `%y` | 四位年 / 两位年 | 跨平台首选 `%Y` |
| `%m` / `%d` | 月 / 日 | 补零 |
| `%H` / `%M` / `%S` | 时 / 分 / 秒 | 24 小时制 |
| `%I` / `%p` | 12 小时制小时 / AM·PM | 依赖 locale |
| `%a` / `%A` | 星期缩写 / 全称 | 依赖 locale |
| `%b` / `%B` | 月份缩写 / 全称 | 依赖 locale |
| `%j` | 一年中第几天 | 001–366 |
| `%U` / `%W` | 周数（周日 / 周一起算） | 第 0 周为年初不完整周 |
| `%G` / `%V` / `%u` | ISO 8601 年 / 周 / 星期 | 生成 ISO 周次用这组 |
| `%z` | UTC 偏移 | `+0800`，**没有冒号** |
| `%Z` | 时区名 | 已弃用，且 locale 相关 |
| `%c` / `%x` / `%X` | locale 的日期时间 / 日期 / 时间 | 依赖 locale |
| `%%` | 字面量 `%` | |

```python
>>> import time
>>> now = time.localtime()
>>> time.strftime("%Y-%m-%d %H:%M:%S", now)
'2026-11-15 18:07:32'
>>> time.strftime("%Y-%m-%dT%H:%M:%S%z", now)
'2026-11-15T18:07:32+0800'
>>> time.strftime("%G-W%V-%u", now)          # ISO 8601 周
'2026-W46-7'
>>> time.strftime("%a, %d %b %Y %H:%M:%S +0000", time.gmtime())  # RFC 5322
'Sun, 15 Nov 2026 10:07:32 +0000'
```

平台差异要留意：

- **`%f` 只属于 `strptime`，不属于 `strftime`**。官方文档明确说明，且 Windows 上 `time.strftime("%f")` 直接抛 `ValueError: Invalid format string`。要微秒用 `datetime.strftime("%f")`。
- **`%s`（Unix 时间戳）是 glibc 扩展**，Windows 上抛 `ValueError`。
- `%F`、`%T`、`%e` 在部分平台可用（本机 Windows 3.14 恰好支持），但不在 ANSI C 标准里，不算可移植。
- 未知指令不报错的平台会原样输出，Windows 则抛 `ValueError`——不要把用户输入直接拼进 format。
- `%Z` 在中文 Windows 上返回「中国标准时间」这种本地化名称，机器可读输出一律避开它。

> [!tip] 要带冒号的时区偏移
> `%z` 只能给出 `+0800`。需要 `+08:00` 的 RFC 3339 形式时用 `datetime`：
> ```python
> from datetime import datetime
> datetime.now().astimezone().isoformat(timespec="seconds")
> # '2026-11-15T18:07:32+08:00'
> ```

## 解析：`strptime`

`strptime(string[, format])` 返回 `struct_time`，**不返回时间戳**，需要的话再 `mktime()`。

```python
>>> time.strptime("2026-11-15 18:07:32", "%Y-%m-%d %H:%M:%S")
time.struct_time(tm_year=2026, tm_mon=11, tm_mday=15, tm_hour=18, tm_min=7,
                 tm_sec=32, tm_wday=6, tm_yday=319, tm_isdst=-1)
>>> time.strptime("15 Nov 26", "%d %b %y")     # 两位年份
time.struct_time(tm_year=2026, ...)
```

要点：

- 默认格式是 `"%a %b %d %H:%M:%S %Y"`（即 `ctime()` 的输出格式）。
- **缺失字段的默认值**是 `(1900, 1, 1, 0, 0, 0, 0, 1, -1)`，不是当前时间。
- 两位年份按 POSIX/ISO C 规则映射：`69–99` → `1969–1999`，`00–68` → `2000–2068`。
- 字符串有多余内容会抛 `ValueError`。
- 月份/星期名来自 C locale（`locale.LC_TIME`，默认 `C` 即英文）。`setlocale` 成中文等语言后，`%b` / `%a` 的输出与 `strptime` 的期望会同时变成该语言；而 `strftime` 走平台 C 库、`strptime` 走纯 Python 的 `_strptime`，两者读 locale 的方式并不一致，混用容易解析失败。
- `%f` 能解析，但 `struct_time` 没有微秒字段，**小数秒被静默丢弃**；要保留微秒用 `datetime.strptime()`。
- `%z` 会填进 `tm_gmtoff`（`tm_zone` 为 `None`），但 `mktime()` **不读** `tm_gmtoff`，仍按本地时区解释——带时区的字符串不要用 `time` 往返。
- 解析与格式化用的是两套实现：`strptime` 是纯 Python（`_strptime` 模块），支持范围以文档为准；`strftime` 走平台 C 库，可能支持更多指令，但不可移植。

## 睡眠：`time.sleep`

```python
time.sleep(0.5)        # 秒，可为小数
```

- 只保证「**至少**睡这么久」，实际可能更长（被其他线程抢占）。
- 被信号打断且信号处理函数没抛异常时会**自动重启**（PEP 475，3.5+），不需要自己处理 `EINTR`。
- 3.11 起 Unix 用 `clock_nanosleep()`、Windows 用高分辨率可等待定时器（约 100 ns 分辨率）；旧版 Windows 的 `sleep` 粒度曾低至约 15.6 ms。
- 别用 `sleep(0)` 当「空操作」，用 `pass`；想让出 CPU 用 `os.sched_yield()`。
- 不要用它做音视频/动画的精确定时，累积误差会漂移。要用「下一帧目标时刻」而不是「每帧睡固定值」：

```python
next_tick = time.perf_counter()
while running:
    do_frame()
    next_tick += 1 / 60
    delay = next_tick - time.perf_counter()
    if delay > 0:
        time.sleep(delay)
    else:
        next_tick = time.perf_counter()   # 追不上就重置，避免雪崩
```

> [!warning] `sleep` 的精度不是分辨率
> 文档强调「real-time 函数的精度可能远低于其单位暗示的精度」。Windows 上 `sleep(0.001)` 在旧系统可能实际睡 15 ms，任何亚毫秒级调度都不能依赖它。

## 时区常量与 `tzset`

| 名称 | 含义 |
| --- | --- |
| `timezone` | 本地**非 DST** 时区偏移，秒，**西为正**（UTC+8 → `-28800`） |
| `altzone` | 本地 DST 时区偏移，秒，西为正 |
| `daylight` | 是否定义了 DST，非零为真 |
| `tzname` | `(标准时区名, 夏令时时区名)` 元组 |
| `tm_gmtoff` / `tm_zone` | 某次 `localtime()` 结果携带的偏移与缩写（推荐用这个） |

- 这些常量在**模块导入时**确定，对历史时间可能错误；需要准确信息时读 `localtime().tm_gmtoff`。
- `tzset()` 仅 Unix 可用，按 `TZ` 环境变量重载规则；Windows 没有 `tzset()`。
- Windows 的 `tzname` 是本地化字符串（中文系统返回「中国标准时间」），不能拿来比较或解析。

```python
import os, time
os.environ["TZ"] = "Asia/Shanghai"
time.tzset()                       # 仅 Unix；Windows 会 AttributeError
```

> [!note] 时区换算的正确工具
> `time` 没有时区对象，只能看「本地」或「UTC」。真正的时区换算用 `zoneinfo`：
> ```python
> from datetime import datetime
> from zoneinfo import ZoneInfo
> datetime.now(ZoneInfo("Asia/Shanghai"))
> ```

## 常用片段

### 计时装饰器

```python
import functools, time

def timed(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        t0 = time.perf_counter_ns()
        try:
            return func(*args, **kwargs)
        finally:
            ms = (time.perf_counter_ns() - t0) / 1e6
            print(f"{func.__name__} 耗时 {ms:.3f} ms")
    return wrapper
```

### 单调超时

```python
deadline = time.monotonic() + 5.0
while time.monotonic() < deadline:
    if try_connect():
        break
    time.sleep(0.1)
else:
    raise TimeoutError("连接超时")
```

### 日志时间戳

```python
def log(msg: str) -> None:
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}")
```

跨时区或多机日志建议统一存 UTC 或带偏移的 ISO 8601，展示时再本地化。

### 时间戳 ↔ 字符串互转

```python
import calendar, time

st = time.strptime("2026-11-15 18:07:32", "%Y-%m-%d %H:%M:%S")
ts_local = time.mktime(st)        # 按本地时区解释
ts_utc = calendar.timegm(st)      # 按 UTC 解释
time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(ts_local))
```

### 睡到某个时刻

```python
def sleep_until(ts: float) -> None:
    """睡到墙钟时刻 ts；期间系统改时间会失效。"""
    while (delay := ts - time.time()) > 0:
        time.sleep(delay)
```

更稳的做法是用 `monotonic` 先算出剩余时长，再用它倒计时。

## 常见陷阱

1. **用 `time.time()` 测耗时**：校时会让结果变负或暴涨，改用 `perf_counter()`。
2. **把 `localtime()` 的结果当 UTC 存**：`localtime()` 已转成本地时间，再 `strftime("%Y-%m-%d %H:%M")` 存库就会差 8 小时；存时间戳或 UTC。
3. **`mktime()` 依赖本地时区**：换台时区不同的机器，同一 `struct_time` 得到的时间戳不同。
4. **`strftime("%f")` 不可用**：Windows 直接 `ValueError`，微秒用 `datetime`。
5. **`%Z` 依赖 locale**：中文系统输出中文时区名，且已被标记为弃用。
6. **两位年份有歧义**：`%y` 的 `68` 是 2068、`69` 是 1969，尽量用 `%Y`。
7. **`strptime` 丢小数秒**：`struct_time` 没有微秒字段。
8. **`struct_time` 做日期加减**：元组运算会拼接/报错，日期运算交给 `datetime` + `timedelta`。
9. **2038 问题**：32 位平台 `time_t` 最大到 2038-01-19，超范围抛 `OverflowError` / `OSError`。
10. **闰秒**：POSIX 时间戳不含闰秒，`tm_sec` 允许 60/61 但常规 `time()` 不会产生。
11. **`sleep(0)` 当空操作**：语义是让出时间片，不是无操作。
12. **`tzname` / `timezone` 常量当权威**：模块导入时快照，历史时间与跨年 DST 都可能错。

## 与 `datetime` / `zoneinfo` 的分工

| 任务 | 推荐 |
| --- | --- |
| 当前时间戳、存库、排序 | `time.time_ns()`（整数无精度损失） |
| 测代码耗时、基准 | `time.perf_counter_ns()` / `timeit` |
| 超时、重试间隔 | `time.monotonic()` |
| 日期加减、月初月末、星期计算 | `datetime` + `timedelta` |
| 时区换算、历史 DST | `datetime` + `zoneinfo` |
| 解析/生成 ISO 8601 | `datetime.fromisoformat()` / `.isoformat()` |
| 解析自定义格式字符串 | `datetime.strptime()`（保留微秒） |
| 睡眠 / 定时 | `time.sleep()` |

一句话：**`time` 给的是「机器用的瞬间」和「秒表」，`datetime` 给的是「人用的日历」。**

## 版本变化

| 版本 | 变化 |
| --- | --- |
| 3.3 | 新增 `perf_counter()`、`monotonic()`、`process_time()`、`clock_gettime()`、`get_clock_info()`；`struct_time` 支持 `tm_gmtoff` / `tm_zone` |
| 3.5 | `monotonic()` 始终可用；`sleep` 被信号打断后自动睡满（PEP 475） |
| 3.6 | `tm_gmtoff` / `tm_zone` 在所有平台可用 |
| 3.7 | 新增全部 `*_ns()` 版本与 `thread_time()` |
| 3.8 | 移除 `time.clock()`（3.3 起废弃，用 `perf_counter` / `process_time`） |
| 3.11 | Unix `sleep` 改用 `clock_nanosleep()`，Windows 改用可等待定时器 |
| 3.13 | `perf_counter()` 与 `monotonic()` 使用同一时钟；Windows `time()` 改用 `GetSystemTimePreciseAsFileTime()` |
| 3.15 | 时间函数接受任意实数（不再限定 `int` / `float`） |

## 最佳实践

- **计时与超时只用单调时钟**，把 `time.time()` 留给「记录瞬间」。
- **存储用整数纳秒或带偏移的 ISO 8601**，展示时再格式化；不要存裸的本地时间字符串。
- **跨平台只用文档列出的 `strftime` 指令**，遇到 `%s`、`%f`、`%F` 先查平台。
- **格式化/解析失败要兜底**：`strptime` 抛 `ValueError`，不要假设输入永远合法。
- **不要长期缓存时区信息**：`tm_zone` / `tm_gmtoff` 只对当次时间有效，跨 DST 边界会变；需要长期时区就持有一个 `ZoneInfo` 对象。
- 需要日历语义时果断切到 `datetime` + `zoneinfo`，别在 `time` 上叠补丁。

## 参考来源

- [time — Time access and conversions（Python 官方文档）](https://docs.python.org/3/library/time.html)
- [datetime — Basic date and time types](https://docs.python.org/3/library/datetime.html)
- [zoneinfo — IANA time zone support](https://docs.python.org/3/library/zoneinfo.html)
- [PEP 418 — Add monotonic time, performance counter, and process time functions](https://peps.python.org/pep-0418/)
- [PEP 475 — Retry system calls failing with EINTR](https://peps.python.org/pep-0475/)

## 相关笔记

- [[Python dataclasses 库]] — `field(default_factory=time.time)` 生成创建时间戳
- [[Python json 库]] — 序列化时间字段时的类型转换
- [[Python 文件读写]] — 日志与文件名的日期后缀
- [[Python msvcrt 库]] — `kbhit()` 轮询循环里配合 `sleep` 降低 CPU 占用
- [[固定步长循环]] — 用 `perf_counter` 驱动固定步长累加器
- [[用 Python 搭建复杂项目]] — 工程化场景下的时间处理约定
