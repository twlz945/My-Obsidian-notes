---
title: Pydantic
date: 2026-10-01
tags:
  - Python
  - Pydantic
  - 数据验证
---

# Pydantic

**Pydantic 是一个基于 Python 类型提示的数据验证与序列化库**，核心通过继承 `BaseModel` 定义数据结构，在实例化时自动校验、转换输入数据，并支持导出为字典、JSON 和 JSON Schema。 V2 版本核心验证逻辑由 Rust 重写，性能较 V1 提升 5–50 倍。

---

## 为什么用它

- **声明式定义**：直接用 Python 类型注解描述数据，无需手写大量 `isinstance` 和 `if` 校验。
- **自动转换**：宽松模式下可将 `"123"` 转为 `int`、字符串日期转为 `datetime` 等。
- **强类型保证**：模型实例化成功后，字段类型和结构即可信任。
- **生态核心**：FastAPI、LangChain、Hugging Face 等大量项目依赖它。

---

## 基础用法

```python
from pydantic import BaseModel, Field, ValidationError

class User(BaseModel):
    id: int
    name: str
    age: int = Field(gt=0, lt=150)
    email: str | None = None

# 自动转换：id 从字符串转为 int
user = User(id="123", name="Alice", age=25)
print(user.id)        # 123 (int)
print(user.model_dump())  # {'id': 123, 'name': 'Alice', ...}

# 校验失败会抛出 ValidationError
try:
    User(id="abc", name="Bob", age=-1)
except ValidationError as e:
    print(e.errors())  # 结构化错误：loc, msg, type
```

---

## V2 核心 API

|功能|V2 方法|说明|
|---|---|---|
|从字典解析|`model_validate(data)`|替代 V1 `parse_obj`|
|从 JSON 解析|`model_validate_json(s)`|直接解析 JSON 字符串|
|转字典|`model_dump()`|替代 V1 `dict()`|
|转 JSON|`model_dump_json()`|替代 V1 `json()`|
|字段约束|`Field(...)`|范围、长度、正则、别名等|
|字段验证|`@field_validator`|替代 V1 `@validator`|
|模型验证|`@model_validator`|跨字段联合校验|
|配置|`model_config = ConfigDict(...)`|替代 V1 内部 `Config` 类|

---

## 字段约束示例

```python
from pydantic import BaseModel, Field

class Product(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    price: float = Field(gt=0, description="价格必须大于0")
    tags: list[str] = Field(default_factory=list)
    sku: str = Field(pattern=r"^[A-Z]{2}-\d{4}$")
```

---

## 模型配置

```python
from pydantic import BaseModel, ConfigDict

class StrictModel(BaseModel):
    model_config = ConfigDict(
        extra="forbid",          # 禁止多余字段
        str_strip_whitespace=True,  # 自动去空格
        validate_assignment=True,   # 赋值时重新校验
        populate_by_name=True,      # 别名与原字段名双向支持
    )
```

---

## 自定义验证器

```python
from pydantic import BaseModel, field_validator, model_validator

class Order(BaseModel):
    items: list[str]
    quantities: list[int]

    @field_validator("items")
    @classmethod
    def check_items(cls, v):
        if not v:
            raise ValueError("订单不能为空")
        return v

    @model_validator(mode="after")
    def check_lengths(self):
        if len(self.items) != len(self.quantities):
            raise ValueError("商品数量必须与数量列表匹配")
        return self
```

---

## 与 FastAPI 集成

```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class UserCreate(BaseModel):
    name: str
    email: str
    age: int

@app.post("/users/")
def create_user(user: UserCreate):
    return {"message": f"Created {user.name}"}
```

FastAPI 会自动完成请求体解析、校验，并生成 Swagger 文档。

---

## V1 → V2 主要变化

|V1|V2|
|---|---|
|`parse_obj()`|`model_validate()`|
|`dict()`|`model_dump()`|
|`json()`|`model_dump_json()`|
|`@validator`|`@field_validator`|
|`class Config`|`model_config = ConfigDict(...)`|
|`orm_mode = True`|`from_attributes = True`|
|`regex=`|`pattern=`|

---

## 使用建议

- **新项目直接用 V2**，性能更好、API 更统一。
- 可变默认值（`list`、`dict`）必须用 `default_factory`，避免共享引用。
- 对外接口建议开启 `extra="forbid"`，防止脏数据侵入。
- 核心数据场景可开启 `strict=True`，杜绝隐式类型转换。