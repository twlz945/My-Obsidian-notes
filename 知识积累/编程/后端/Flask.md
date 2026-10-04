---
title: Flask
date: 2026-09-26
tags:
  - Python
  - 后端开发
  - Flask
---

# Flask

Flask 是一个使用 Python 编写的**轻量级 Web 应用框架**，属于"微框架"（microframework）范畴，以简洁、灵活和高可扩展性著称。

---

## Flask 是什么？

Flask 的核心仅由两个组件构成：**Werkzeug**（WSGI 工具包，负责路由、请求/响应处理）和 **Jinja2**（模板引擎，负责渲染 HTML 页面）。它被称为"微框架"，并不是说功能弱，而是指**核心精简、不强制绑定任何数据库、ORM、表单验证或用户认证组件**，开发者可以根据项目需求自由选择第三方扩展。

其设计哲学遵循 Python 的"显式优于隐式"原则——每个功能都需要你明确引入和配置，换来的是对项目的完全掌控。

---

## 核心特性

- **轻量简洁**：核心代码极少，学习曲线平缓，易于上手
- **高度灵活**：不强制项目结构或依赖组件，开发者拥有完全控制权
- **扩展生态丰富**：通过扩展按需添加功能，常见扩展包括：
    - `Flask-SQLAlchemy`：数据库 ORM
    - `Flask-Login` / `Flask-JWT-Extended`：用户认证
    - `Flask-WTF`：表单验证与 CSRF 防护
    - `Flask-RESTful`：RESTful API 开发
    - `Flask-Migrate`：数据库迁移
    - `Flask-Caching`：缓存
- **内置开发工具**：开发服务器 + 交互式调试器，支持热重载
- **蓝图（Blueprint）**：支持模块化组织代码，适合中大型项目拆分
- **100% WSGI 兼容**：可部署在 Gunicorn、uWSGI、Nginx 等任何 WSGI 服务器上

---

## 快速上手示例

```python
from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, Flask!"

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    return jsonify({"user_id": user_id, "name": "Alice"})

if __name__ == '__main__':
    app.run(debug=True)
```

启动后访问 `http://127.0.0.1:5000` 即可看到效果。

---

## 企业级项目架构

Flask 项目推荐采用**应用工厂模式 + 蓝图模块化**结构，与你之前看到的 `src` 布局理念一致：

```text
project_root/
├── src/
│   └── your_package/
│       ├── __init__.py          # 应用工厂 create_app()
│       ├── extensions.py        # 扩展对象集中初始化（db, login_manager等）
│       ├── config.py            # 多环境配置类
│       ├── api/                 # 路由层（按蓝图拆分）
│       │   ├── __init__.py
│       │   ├── auth.py          # 认证相关路由
│       │   └── users.py         # 用户相关路由
│       ├── models/              # 数据库模型层
│       │   ├── __init__.py
│       │   └── user.py
│       ├── services/            # 业务逻辑层
│       │   ├── __init__.py
│       │   └── user_service.py
│       ├── schemas/             # 数据校验层（Marshmallow/Pydantic）
│       └── utils/               # 通用工具函数
├── tests/
├── .env
├── pyproject.toml
└── run.py                       # 启动入口
```

关键设计模式：

- **应用工厂**：用 `create_app()` 函数创建应用实例，方便多环境配置和测试隔离
- **蓝图模块化**：每个功能模块独立为蓝图，拥有自己的路由、模板和静态文件
- **扩展延迟初始化**：在 `extensions.py` 中创建扩展对象但不绑定 app，在工厂函数中调用 `init_app()` 完成绑定，避免循环导入

---

## 适用场景

|场景|说明|
|---|---|
|**中小型 Web 应用**|个人博客、企业官网、内部工具系统|
|**RESTful API 服务**|为前端（Vue/React）或移动端提供数据接口|
|**微服务架构**|作为独立服务模块，按业务域拆分、独立部署|
|**机器学习/AI 服务部署**|将模型封装为 API 供外部调用|
|**快速原型开发**|最小成本验证想法，快速迭代|
|**数据可视化仪表板**|结合 Pandas、Plotly 等展示数据分析结果|

---

## 与 Django / FastAPI 对比

| 维度       | Flask          | Django                 | FastAPI            |
| -------- | -------------- | ---------------------- | ------------------ |
| **定位**   | 轻量微框架          | 全功能重型框架                | 高性能异步框架            |
| **性能**   | ⭐⭐⭐            | ⭐⭐                     | ⭐⭐⭐⭐⭐              |
| **异步支持** | 需扩展（同步为主）      | 3.1+ 部分支持              | 原生异步               |
| **开箱即用** | 弱（需自组装）        | 极强（ORM/Admin/Auth 全内置） | 中等（需自组装）           |
| **自动文档** | ❌ 需插件          | ❌ 需插件                  | ✅ 内置 Swagger/ReDoc |
| **学习曲线** | 平缓             | 较陡                     | 中等                 |
| **适合场景** | 中小项目、高度定制、内部工具 | 大型单体后台、SaaS 平台         | 高并发 API、微服务、AI 服务  |
|          |                |                        |                    |

---

## 选型建议

- **选 Flask**：项目规模中等、需要高度自由定制、团队偏好"自己组装"而非"全家桶"、开发内部工具或轻量 API 服务
- **选 Django**：大型单体应用、权限体系复杂、需要快速落地完整业务（Admin/ORM/Auth 开箱即用）
- **选 FastAPI**：高并发接口、微服务架构、AI 推理服务、需要自动生成 API 文档

## 相关

- [[FastAPI]]
- [[../教程/python/用 Python 搭建复杂项目]]
