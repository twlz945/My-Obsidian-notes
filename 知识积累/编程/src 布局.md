**src 布局就是把 Python 项目的所有可导入源码放进 `src/` 目录，并在其中再放一个真正的包目录，从而把“源码”和“测试、文档、配置、脚本”物理隔离。**

### 典型结构

```text
my_project/
├── pyproject.toml
├── README.md
├── .gitignore
├── tests/
│   ├── __init__.py
│   └── test_core.py
└── src/
    └── my_project/
        ├── __init__.py
        ├── core.py
        └── cli.py
```

关键点是：**`src/` 本身不是包**，`src/my_project/` 才是真正可导入的包。

### 和扁平布局的区别

|对比项|src 布局|扁平布局|
|---|---|---|
|源码位置|`src/my_project/`|根目录 `my_project/`|
|导入方式|`from my_project.core import ...`|`from my_project.core import ...`|
|运行方式|推荐 `pip install -e .` 后运行|可能直接 `python main.py`|
|适用场景|库、可安装包、中大型项目|小脚本、原型|

扁平布局把包直接放在根目录，运行 `python main.py` 时，Python 会把当前目录加入 `sys.path`，容易意外导入本地文件而不是已安装的包，导致开发和生产环境行为不一致。

### 为什么推荐 src 布局

1. **避免意外导入**：源码不在根目录，不会因当前工作目录污染导入。
2. **打包更干净**：构建工具只打包 `src/` 下的代码，不会误带 `tests/`、`docs/`。
3. **测试更可靠**：安装后可直接用绝对导入跑 pytest，不需要手动改 `sys.path`。
4. **IDE 支持更好**：PyCharm、VS Code 等更容易识别源根。

### 使用时的注意事项

- 开发时先用 `pip install -e .` 或 `uv sync` 安装项目，再运行代码。
- 不要直接 `python src/my_project/core.py`，容易报 `ModuleNotFoundError`。
- 推荐用 `python -m my_project.cli` 或安装后的入口命令运行。
- `pyproject.toml` 中要配置 `packages` 或 `package-dir`，告诉构建工具源码在 `src/` 下。

简单说：**小脚本可以用扁平布局；只要项目会打包、发布、写测试或多人协作，优先用 src 布局。**