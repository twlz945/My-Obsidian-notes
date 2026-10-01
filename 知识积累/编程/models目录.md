---
title: models 目录
date: 2026-09-26
tags:
  - Python
  - 项目架构
  - 后端开发
---

# models 目录

`models/` 目录是复杂 Python 项目的**数据结构定义中心**，它的核心职责是**只定义数据结构与校验规则，绝不掺杂业务逻辑**（业务逻辑应放在 `services/` 层）。

## 1. 核心职责与原则

- **只定义数据契约**：明确项目中的实体（如用户、订单、商品）有哪些字段、字段类型、默认值、校验规则。
- **零业务逻辑**：不包含任何流程控制、数据库操作或复杂计算，仅作为数据载体。
- **跨层复用**：`api` 层用模型做参数校验，`services` 层用模型做数据传递，`repositories` 层用模型做 ORM 映射。

## 2. 推荐实现方式（2026年主流方案）

### 方案一：Pydantic（推荐，适用于 Web 项目 / 数据校验场景）

适合 [[FastAPI]]、[[Flask]] 等框架，自带数据校验、序列化、类型检查能力：

```python
# src/your_package/models/user.py
from pydantic import BaseModel, Field, EmailStr
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    """用户基础模型（用于创建/更新）"""
    username: str = Field(..., min_length=3, max_length=20, description="用户名")
    email: EmailStr = Field(..., description="邮箱地址")
    age: Optional[int] = Field(None, ge=0, le=150, description="年龄")

class UserResponse(UserBase):
    """用户响应模型（对外暴露，含数据库生成字段）"""
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True  # 兼容 ORM 模式
```

### 方案二：dataclass（适用于纯 Python 项目 / 轻量级场景）

适合不需要 Web 框架、仅需数据载体的场景，依赖 Python 标准库：

```python
# src/your_package/models/order.py
from dataclasses import dataclass, field
from datetime import datetime
from typing import List

@dataclass
class OrderItem:
    """订单项"""
    product_id: int
    quantity: int
    price: float

@dataclass
class Order:
    """订单模型"""
    order_id: str
    user_id: int
    items: List[OrderItem]
    total_amount: float = field(init=False)  # 自动计算，不通过构造函数传入
    created_at: datetime = field(default_factory=datetime.now)

    def __post_init__(self):
        """初始化后自动计算总金额（仅简单计算，复杂逻辑仍放 services 层）"""
        self.total_amount = sum(item.price * item.quantity for item in self.items)
```

### 方案三：SQLAlchemy ORM 模型（适用于数据库映射场景）

如果项目直接使用 SQLAlchemy，模型层也可同时作为 ORM 映射类：

```python
# src/your_package/models/product.py
from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.orm import declarative_base
from datetime import datetime

Base = declarative_base()

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    price = Column(Float, nullable=False)
    stock = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.now)
```

## 3. 目录内文件组织建议

按业务实体拆分文件，避免单个文件过大：

```text
models/
├── __init__.py          # 统一导出常用模型，简化导入路径
├── user.py              # 用户相关模型
├── order.py             # 订单相关模型
├── product.py           # 商品相关模型
└── base.py              # 基础模型（如分页参数、通用响应结构）
```

`__init__.py` 示例：

```python
# src/your_package/models/__init__.py
from .user import UserBase, UserResponse
from .order import Order, OrderItem
from .product import Product

__all__ = ["UserBase", "UserResponse", "Order", "OrderItem", "Product"]
```

## 4. 常见误区与避坑指南

- **不要在模型里写数据库操作**：比如 `User.save()`、`Order.query_all()` 这类方法应放在 `repositories/` 层。
- **不要在模型里写复杂业务计算**：比如 `Order.calculate_discount()` 应放在 `services/` 层，模型仅做简单数据计算。
- **区分输入模型和输出模型**：创建用户时不需要 `id` 和 `created_at`，但返回用户信息时需要，建议用继承拆分（如 `UserCreate` / `UserResponse`）。
- **类型注解必须完整**：配合 `mypy` 做静态检查，避免运行时类型错误。

简单总结：`models/` 就是项目的"数据字典"，所有其他层都基于这里定义的结构来传递和校验数据，保持它的纯粹性是架构清晰的关键。
