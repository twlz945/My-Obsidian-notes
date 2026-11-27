---
title: Python pyproject.toml
date: 2026-11-22
tags:
  - Python
  - 打包
  - 工程化
  - 教程
aliases:
  - pyproject
  - pyproject.toml
  - PEP 621
  - Python 打包配置
related:
  - "[[src 布局]]"
  - "[[用 Python 搭建复杂项目]]"
  - "[[单元测试]]"
  - "[[Python进阶阶段学习规划表]]"
---

# Python pyproject.toml

`pyproject.toml` 是现代 Python 项目的**单一配置入口**。它把过去散落在 `setup.py`、`setup.cfg`、`requirements.txt`、`tox.ini`、`.flake8`、`mypy.ini` 里的东西收进一个文件，由几张互相独立的表组成：

- `[build-system]`：声明用哪个构建后端（PEP 518 / 517）
- `[project]`：项目元数据与依赖（PEP 621）
- `[dependency-groups]`：只在本地用的开发依赖（PEP 735）
- `[tool.*]`：第三方工具自己的配置

它只是 TOML 文件，没有运行时；真正读它的是构建后端（hatchling、setuptools）、包管理器（pip、uv）和各个工具的 CLI。所以「写得对不对」取决于谁在读——这也是大部分报错的来源。

本笔记以 **hatchling** 为主、setuptools 作对照，规范以 2026 年的 PyPA 文档为准（含 PEP 639 许可证表达式、PEP 735 依赖组）。

## 三份模板

先给可直接复制的成品，后面再逐字段解释。三份从简到繁，按项目类型挑一份。

### 1. 最小应用：不发布，只管理依赖

```toml
# pyproject.toml —— 应用/脚本项目，不构建发行包
[project]
name = "todo-app"
version = "0.1.0"
description = "一个命令行待办工具"
requires-python = ">=3.11"
dependencies = [
    "httpx>=0.27,<1",
    "rich>=13",
]

[dependency-groups]
dev = ["pytest>=8", "ruff>=0.6"]

[tool.ruff]
line-length = 100
target-version = "py311"
```

没有 `[build-system]` 就不构建 wheel：`uv sync` 会把 `dependencies` 和默认的 `dev` 组建进虚拟环境，源码用 `python -m todo_app` 直接跑；只用 pip 时，`pip install --group dev` **只装开发组**，运行时依赖要另外装——或者干脆补上构建系统，用 `pip install -e .` 一步到位（见模板 2）。

### 2. 可发布库：hatchling + src 布局

```toml
[build-system]
requires = ["hatchling>=1.27"]
build-backend = "hatchling.build"

[project]
name = "mypkg"
version = "0.1.0"
description = "A small example library"
readme = "README.md"
requires-python = ">=3.10"
license = "MIT"
license-files = ["LICENSE"]
authors = [{ name = "Your Name", email = "you@example.com" }]
keywords = ["example", "library"]
classifiers = [
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.10",
    "Typing :: Typed",
]
dependencies = ["attrs>=23"]

[project.optional-dependencies]
cli = ["typer>=0.12"]
all = ["mypkg[cli]"]

[project.urls]
Homepage = "https://github.com/you/mypkg"
Issues = "https://github.com/you/mypkg/issues"

[project.scripts]
mypkg = "mypkg.cli:main"

[dependency-groups]
test = ["pytest>=8", "pytest-cov>=5"]
docs = ["sphinx>=7", "furo"]
typing = ["mypy>=1.11"]
dev = [{ include-group = "test" }, { include-group = "typing" }]

[tool.hatch.build.targets.wheel]
packages = ["src/mypkg"]
```

源码放在 `src/mypkg/`，`packages` 告诉 hatchling 只打包这个目录，其余（tests、docs）不进 wheel。

### 3. 内部服务：带完整工具链与动态版本

```toml
[build-system]
requires = ["hatchling>=1.27"]
build-backend = "hatchling.build"

[project]
name = "orders-api"
dynamic = ["version"]
description = "订单服务"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115",
    "uvicorn[standard]>=0.30",
    "pydantic-settings>=2.4",
]

[dependency-groups]
dev = ["pytest>=8", "httpx>=0.27"]
lint = ["ruff>=0.6"]
types = ["mypy>=1.11"]

[tool.hatch.version]
path = "src/orders_api/__init__.py"   # 文件里写 __version__ = "0.3.0"

[tool.hatch.build.targets.wheel]
packages = ["src/orders_api"]

[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B"]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q"

[tool.mypy]
python_version = "3.12"
strict = true
```

`dynamic = ["version"]` 表示版本由后端从源码读取，`[project]` 里就**不能**再写 `version`。

> [!tip] 模板怎么选
> 不发布 → 模板 1；发 PyPI → 模板 2；部署服务 → 模板 3。模板 3 删掉 `[build-system]` 与 `[tool.hatch.*]` 就退化成模板 1。

## 文件由哪几张表组成

| 表 | 谁读 | 作用 | 会进发行包吗 |
| --- | --- | --- | --- |
| `[build-system]` | 构建前端（pip、build、uv） | 指定构建后端及其依赖 | 否 |
| `[project]` | 构建后端 | 名称、版本、依赖等元数据 | 是（转成 `METADATA`） |
| `[dependency-groups]` | uv、pip、tox 等 | 本地开发依赖 | **否** |
| `[tool.*]` | 对应工具 | 工具配置 | 否 |

几个常被误解的点：

- **`[project]` 不是给 pip 直接读的**。pip 装本地项目时会先调构建后端，由后端把 `[project]` 转成 wheel 里的 `METADATA`，pip 再读那份元数据。所以元数据写错，往往在构建阶段才报错。
- **`[dependency-groups]` 是顶层表**，不在 `[project]` 下面，也不发布。`pip install 包名[dev]` 装不到它。
- **`[tool.*]` 是约定俗成的命名空间**，谁拥有 PyPI 上的名字谁就能用 `tool.名字`；构建后端不认识就忽略。
- TOML 本身没有 schema，**未知键在 `[project]` 里会被构建后端拒绝**，在 `[tool.*]` 里通常被忽略。

## `[build-system]`

```toml
[build-system]
requires = ["hatchling>=1.27"]
build-backend = "hatchling.build"
```

- `requires`：构建时需要安装的包，**必填**。pip 会在隔离的临时环境里装它们，再执行后端。
- `build-backend`：后端入口对象，省略时默认 `setuptools.build_meta:__legacy__`。
- 两者都遵循 PEP 517：前端（pip/build/uv）只管调用 `build_wheel()` / `build_sdist()`，不关心后端是哪个。

常用后端：

| 后端 | `build-backend` | 特点 |
| --- | --- | --- |
| hatchling | `hatchling.build` | 现代、配置少，Hatch 官方后端 |
| setuptools | `setuptools.build_meta` | 兼容性最广，老项目与 C 扩展多 |
| flit-core | `flit_core.buildapi` | 极简，适合纯 Python 单模块 |
| poetry-core | `poetry.core.masonry.api` | Poetry 生态 |
| uv_build | `uv_build` | uv 自带，配置最少、较新 |

**不写 `[build-system]` 会怎样**：pip 退回 PEP 517 的默认值（`setuptools>=40.8.0` + legacy 后端）。这要求环境里有 setuptools，而且包发现走老逻辑，很容易打出空 wheel。**只要项目要构建，就显式写清楚。**

### hatchling 的包发现

```toml
[tool.hatch.build.targets.wheel]
packages = ["src/mypkg"]
```

`packages` 等价于「只包含这个目录，并把最外层路径折叠掉」，所以 `src/mypkg/__init__.py` 在 wheel 里是 `mypkg/__init__.py`。src 布局**建议显式写**，否则 hatchling 按项目名在根目录找同名包，找不到就产出空 wheel。

### setuptools 对照

```toml
[build-system]
requires = ["setuptools>=77", "wheel"]
build-backend = "setuptools.build_meta"

[tool.setuptools.packages.find]
where = ["src"]
include = ["mypkg*"]
exclude = ["mypkg.tests*"]
```

setuptools 的 `find` 会扫描 `where` 目录，按包名 glob 匹配。注意 `exclude = ["tests"]` 不会排除子包，要写 `"tests*"`。

## `[project]` 元数据

```toml
[project]
name = "mypkg"            # 必填，且不能 dynamic（后端不允许）
version = "0.1.0"         # 必填，但可交给 dynamic
description = "一句话简介"
readme = "README.md"
requires-python = ">=3.10"
```

### 必填字段

| 字段 | 规则 |
| --- | --- |
| `name` | 必须静态写死，不能进 `dynamic`；会按 PEP 503 规范化（`My_Pkg` → `my-pkg`） |
| `version` | 必须静态写死或列进 `dynamic`；遵循 PEP 440（`1.0.0rc1` 合法，`v1.0` 不推荐） |

### 描述性字段

- `description`：一行简介，写入 `Summary`。
- `readme`：字符串路径，或 `{ file = "README.md", content-type = "text/markdown" }`。`.md` / `.rst` 后缀会自动推断类型，其他后缀必须显式给 `content-type`。
- `requires-python`：PEP 440 说明符，如 `">=3.10"`、`">=3.9,<3.14"`。它决定 pip 允许在哪些解释器上安装。
- `authors` / `maintainers`：`[{ name = "...", email = "..." }]`，`name` 与 `email` 至少给一个。
- `keywords`：字符串数组，写入 `Keywords`。
- `classifiers`：Trove 分类器数组。**`License ::` 开头的分类器已随 PEP 639 弃用**，改用 `license` 字段。
- `urls`：`{ Homepage = "...", Issues = "..." }`，标签建议用 PyPI 认可的名字。

### 许可证：PEP 639 新写法

```toml
[project]
license = "MIT"                     # SPDX 表达式，推荐
license-files = ["LICENSE", "licenses/*"]
```

- `license` 现在是**字符串**，内容必须是合法的 SPDX 表达式，如 `"MIT"`、`"Apache-2.0"`、`"MIT OR Apache-2.0"`。
- `license-files` 是 glob 数组，匹配到的文件会随 sdist 和 wheel 分发，并记录在 `License-File` 元数据里。
- 旧写法 `license = { text = "MIT" }` 和 `license = { file = "LICENSE" }` 已弃用；`license-files` 与旧 table 写法**不能同时出现**，否则构建报错。

> [!warning] 旧写法会踩坑
> 很多教程还在用 `license = { text = "MIT" }` + `License :: OSI Approved :: MIT License`。前者已弃用，后者与新的 `license` 字符串同时出现时，构建工具可能直接报错。新项目只写 `license = "MIT"` + `license-files`。

### 动态字段

```toml
[project]
name = "orders-api"
dynamic = ["version"]

[tool.hatch.version]
path = "src/orders_api/__init__.py"
```

- `dynamic` 里列出的字段，构建后端负责提供；**同一字段不能既静态又 dynamic**（列表/表类型的字段例外，规范允许静态值 + 追加）。
- `name` 永远不能 dynamic。
- 常见动态字段：`version`、`readme`、`classifiers`、`dependencies`。

三种动态版本来源：

| 方式 | 配置 | 适用 |
| --- | --- | --- |
| 读源码变量 | `[tool.hatch.version] path = "src/pkg/__init__.py"` | 最简单，版本写在 `__version__` |
| 从 Git 标签推导 | `hatch-vcs` + `[tool.hatch.version] source = "vcs"` | 无需手改版本 |
| setuptools 读属性 | `[tool.setuptools.dynamic] version = { attr = "pkg.__version__" }` | setuptools 项目 |

### 入口点

```toml
[project.scripts]
mypkg = "mypkg.cli:main"

[project.gui-scripts]
mypkg-gui = "mypkg.gui:main"

[project.entry-points."pytest11"]
mypkg-plugin = "mypkg.pytest_plugin"
```

- `[project.scripts]` 生成 `console_scripts`，安装后命令行可执行 `mypkg`。
- `[project.gui-scripts]` 生成 `gui_scripts`（Windows 下不弹控制台窗口）。
- `[project.entry-points.<组名>]` 用于插件发现，组名由宿主工具约定（如 pytest 的 `pytest11`）。
- 值格式是 `模块路径:函数名`，函数在安装后由生成的脚本调用。

### 2025 年新增字段（了解即可）

`import-names` / `import-namespaces`（PEP 794）用来声明项目提供的导入名，供工具做安装冲突检测：

```toml
[project]
name = "pillow"
import-names = ["PIL"]
```

这是 2025 年 10 月才进规范的新字段，**构建后端支持还不普遍**，现在写不写都不影响安装。看到别人的 `pyproject.toml` 里有它，知道是干什么的即可。

## 依赖

### `dependencies`：运行依赖

```toml
[project]
dependencies = [
    "httpx>=0.27,<1",                                  # 版本区间
    "uvicorn[standard]>=0.30",                        # 带 extras
    "importlib-metadata>=7; python_version < '3.10'",  # 环境标记
]
```

每条都是 PEP 508 依赖说明符：`名称[extras] 版本约束; 环境标记`。字符串里**不要**出现 `pip install` 的写法（`-e`、`-r`、`--index-url` 都不合法）。

版本说明符速查（PEP 440）：

| 写法 | 含义 | 例子 |
| --- | --- | --- |
| `==1.4.*` | 该系列的任意版本 | 接受 `1.4.0`、`1.4.9` |
| `>=1.2,<2` | 区间 | 库依赖的常见写法 |
| `~=1.4.2` | 兼容版本 | 等于 `>=1.4.2,<1.5.0` |
| `~=1.4` | 兼容次版本 | 等于 `>=1.4,<2` |
| `!=1.4.0` | 排除 | 配合区间使用 |
| `===1.4.0` | 完全匹配（含非规范版本） | 极少用 |

**库的依赖要宽松**（`>=` 或 `~=`），**应用的依赖才用锁文件精确固定**。在库里写死 `==` 会把版本冲突传染给所有使用者。

### `optional-dependencies`：给使用者的可选功能

```toml
[project.optional-dependencies]
cli = ["typer>=0.12"]
excel = ["openpyxl>=3.1"]
all = ["mypkg[cli,excel]"]     # 自引用，一次装齐
```

- extras 会发布到 PyPI，用户用 `pip install mypkg[cli]` 安装。
- extras 名称只能用字母、数字和 `-`，会规范化为小写。
- 可以自引用其他 extras（`mypkg[cli]`），主流包管理器都支持。

### `[dependency-groups]`：给开发者的本地依赖

```toml
[dependency-groups]
test = ["pytest>=8", "pytest-cov>=5"]
lint = ["ruff>=0.6", "mypy>=1.11"]
dev = [{ include-group = "test" }, { include-group = "lint" }]
```

- **不会发布**：构建后端必须忽略它，`pip install 包名[dev]` 装不到。
- 支持 `{ include-group = "..." }` 组合，方便 `dev` 汇总。
- 与 `requirements.txt` 相比：位置固定、名字标准化、可被工具发现；缺点是仍不支持 `-e`、索引、哈希等 pip 专属语法。
- 安装方式：`uv sync --group dev`、`pip install --group dev`（需较新的 pip，本机 26.2 实测支持）。

**extras 与 dependency-groups 的边界**：

| 维度 | `optional-dependencies`（extras） | `[dependency-groups]` |
| --- | --- | --- |
| 发布 | 会 | 不会 |
| 使用者 | 最终用户 | 项目开发者 / CI |
| 安装方式 | `pip install 包[extra]` | `uv sync --group test` |
| 典型内容 | 可选功能（cli、excel） | pytest、ruff、mypy、docs |
| 是否安装项目本身 | 会 | 不会（需另外 `pip install -e .`） |

> [!warning] 把开发依赖放进 extras 的代价
> 很多项目写 `[project.optional-dependencies] dev = ["pytest"]`，然后 `pip install -e ".[dev]"`。能用，但会把 pytest 发布成包对外的「功能」，而且每次都要连项目一起装。新项目优先用 `[dependency-groups]`。

### 环境标记

```toml
[project]
dependencies = [
    "colorama>=0.4; platform_system == 'Windows'",
    "jax; sys_platform == 'linux'",
    "numpy; python_version >= '3.11'",
]
```

常用变量：`python_version`、`sys_platform`、`platform_system`、`platform_machine`、`implementation_name`。标记里的版本号**必须加引号**，标记外的版本号**不能加引号**。

### 锁文件

`pyproject.toml` 只声明「允许的版本范围」，锁定实际版本靠锁文件：

- uv：`uv.lock`（`uv lock` 生成）
- Poetry：`poetry.lock`
- pip-tools：`requirements.txt`（带哈希）

锁文件要提交到 Git，`pyproject.toml` 与锁文件一起才能复现环境。

## `[tool.*]` 工具配置

### ruff

```toml
[tool.ruff]
line-length = 100
target-version = "py312"
exclude = [".venv", "build", "dist"]

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B"]
ignore = ["E501"]

[tool.ruff.format]
quote-style = "double"
```

`select` / `ignore` 放在 `[tool.ruff.lint]` 下（旧版的顶层写法已废弃）。

### pytest

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q --strict-markers"
pythonpath = ["src"]
markers = ["slow: 慢速测试"]
```

- 表名是 `[tool.pytest.ini_options]`，**不是** `[tool.pytest]`。
- `pythonpath = ["src"]` 让 src 布局不用安装也能跑测试（pytest 7+）。

### mypy

```toml
[tool.mypy]
python_version = "3.12"
strict = true
files = ["src"]
exclude = ["build/"]

[[tool.mypy.overrides]]
module = ["第三方无类型.*"]
ignore_missing_imports = true
```

`strict = true` 会打开一批检查（`disallow_untyped_defs`、`warn_return_any` 等），新项目建议直接开。

### 其他工具

| 工具 | 表名 | 一句话 |
| --- | --- | --- |
| coverage | `[tool.coverage.run]` / `[tool.coverage.report]` | 覆盖率统计 |
| black | `[tool.black]` | 格式化（ruff format 可替代） |
| isort | `[tool.isort]` | 导入排序（ruff 的 `I` 规则可替代） |
| pyright | `[tool.pyright]` | 另一套类型检查器 |
| tox | `[tool.tox]` | 多环境测试（新版支持 TOML 配置） |

并不是所有工具都支持 pyproject：老版本的 flake8 只认 `.flake8` / `setup.cfg`，配置前先查工具文档。

## 构建与验证

```bash
# 1) 语法检查（标准库，零依赖）
python -c "import tomllib; tomllib.load(open('pyproject.toml','rb'))"

# 2) 构建 sdist + wheel（需要 pip install build）
python -m build            # 产物在 dist/
uv build                   # 用 uv 时

# 3) 检查元数据与 README
twine check dist/*

# 4) 看 wheel 里到底装了什么
python -m zipfile -l dist/mypkg-0.1.0-py3-none-any.whl

# 5) 可编辑安装并验证入口点
pip install -e .
mypkg --help

# 6) 读回安装后的元数据
python -c "from importlib.metadata import metadata; m=metadata('mypkg'); print(m['Name'], m['Version'], m.get('License-Expression'))"
```

几个经验：

- **构建隔离**：`python -m build` 默认在隔离环境里装 `requires`，能暴露「本地碰巧装了所以能构建」的问题。调试时可加 `--no-isolation`。
- **先看 wheel 再上传**：空 wheel、误带测试文件、许可证缺失，都能在这一步发现。
- **validate-pyproject**（第三方）可以在 CI 里做 schema 级校验，比 `tomllib` 只查语法更严格。
- 发布前至少跑一遍 `build` + `twine check`，这两步覆盖了 90% 的元数据错误。

## 字段速查表

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `name` | 是 | 分发名，不能 dynamic，会规范化 |
| `version` | 是 | PEP 440 版本，可 dynamic |
| `description` | 否 | 一行简介 |
| `readme` | 否 | 路径或 `{file, content-type}` |
| `requires-python` | 否 | 建议写，如 `">=3.10"` |
| `license` | 否 | SPDX 表达式字符串 |
| `license-files` | 否 | glob 数组，随包分发 |
| `authors` / `maintainers` | 否 | `[{name, email}]` |
| `keywords` | 否 | 字符串数组 |
| `classifiers` | 否 | Trove 分类器，`License ::` 已弃用 |
| `urls` | 否 | `{标签 = URL}` |
| `dependencies` | 否 | PEP 508 数组，默认空 |
| `optional-dependencies` | 否 | extras 表 |
| `scripts` / `gui-scripts` | 否 | 命令行入口 |
| `entry-points` | 否 | 插件组 |
| `dynamic` | 否 | 交由后端提供的字段列表 |
| `import-names` | 否 | PEP 794 新字段，后端支持有限 |
| `[build-system].requires` | 是（若该表存在） | 构建依赖 |
| `[build-system].build-backend` | 否 | 默认 legacy setuptools |
| `[dependency-groups].<组名>` | 否 | 开发依赖，不发布 |

## 常见陷阱

1. **忘了 `[build-system]`**：pip 退回 legacy setuptools，包发现失败或打出空 wheel。
2. **src 布局没配 `packages`**：hatchling 在根目录找不到同名包，wheel 里只有元数据。
3. **`license` 用旧 table 写法**：`{text = "MIT"}` 已弃用，且与 `license-files` 互斥。
4. **同时写 `license` 和 `License ::` 分类器**：可能直接构建报错。
5. **开发依赖放进 extras**：`pytest` 变成对外功能，`pip install pkg[dev]` 还要连项目一起装。
6. **以为 `dependency-groups` 会发布**：`pip install pkg[dev]` 装不到，它只存在于源码树。
7. **`version` 两处维护**：`pyproject.toml` 和 `__init__.py` 各写一遍，忘了同步；用 `dynamic` + 单一来源。
8. **`dynamic` 与静态值同时写**：同一字段既出现在 `[project]` 又列进 `dynamic`，后端报错（列表/表类型例外）。
9. **发行名与导入名混淆**：`name = "mypkg-cli"` 但包目录叫 `mypkg`，`packages` 配错就找不到代码。
10. **`readme` 文件不存在**：构建失败，错误信息通常是「无法读取 README」。
11. **`requires-python` 与实际语法不符**：在 3.9 上装却用了 3.10 的 `match`，安装成功、运行时炸。
12. **`[tool.pytest]` 写错表名**：不是 `[tool.pytest.ini_options]` 就完全不生效，而且不报错。
13. **在 `[project]` 里加自定义键**：PEP 621 不允许未知键，构建后端会拒绝；自定义配置放 `[tool.你的工具]`。
14. **库里写死 `==` 版本**：把依赖冲突传染给所有使用者，库用 `>=` / `~=`，应用用锁文件。
15. **entry point 指向不存在的函数**：安装成功，执行命令时 `ModuleNotFoundError` / `AttributeError`。

## 参考来源

- [pyproject.toml specification（PyPA）](https://packaging.python.org/en/latest/specifications/pyproject-toml/)
- [Writing your pyproject.toml（PyPA 指南）](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/)
- [PEP 518 — Specifying Minimum Build System Requirements](https://peps.python.org/pep-0518/)
- [PEP 621 — Storing project metadata in pyproject.toml](https://peps.python.org/pep-0621/)
- [PEP 639 — License Expressions](https://peps.python.org/pep-0639/)
- [PEP 735 — Dependency Groups](https://peps.python.org/pep-0735/)
- [PEP 794 — import-names / import-namespaces](https://peps.python.org/pep-0794/)
- [Hatchling 构建配置](https://hatch.pypa.io/latest/config/build/)
- [Hatchling 版本配置](https://hatch.pypa.io/latest/version/)
- [setuptools：用 pyproject.toml 配置](https://setuptools.pypa.io/en/latest/userguide/pyproject_config.html)
- [uv：依赖管理](https://docs.astral.sh/uv/concepts/projects/dependencies/)

## 相关笔记

- [[src 布局]] — 源码目录与非源码分离，`packages` 配置的依据
- [[用 Python 搭建复杂项目]] — 工程化目录、依赖管理与环境隔离
- [[单元测试]] — pytest 配置与测试目录约定
- [[Python进阶阶段学习规划表]] — 工程化阶段的学习路径
