---
title: JSON
date: 2026-09-26
tags:
  - 数据格式
  - JSON
  - 后端开发
---

# JSON

## 定义

JSON（JavaScript Object Notation）是一种轻量级的数据交换格式，采用完全独立于编程语言的文本格式来存储和表示数据。它易于人阅读和编写，同时也易于机器解析和生成。JSON 是一种**文本格式**，是 JavaScript 语言的一个子集，但因其简洁性和广泛支持，已成为当今最主流的数据交换格式之一。

JSON 由 Douglas Crockford 在 2001 年开始推广使用，2013 年由 ECMA-404 标准化为 **ECMA-404** 标准，2017 年由 IETF 发布为 **RFC 8259** 标准。

## 历史背景

- **2001年**：Douglas Crockford 提出 JSON 规范，最初作为 XML 的轻量级替代方案
- **2005-2006年**：随着 AJAX 技术的兴起，JSON 开始在 Web 开发中广泛使用
- **2013年**：ECMA International 发布 ECMA-404 标准
- **2017年**：IETF 发布 RFC 8259，将 JSON 正式纳入互联网标准
- **2020年代**：JSON 成为 API 数据交换的事实标准，广泛应用于前后端通信、配置文件、NoSQL 数据库等领域

## 语法规范

### 基本规则

1. **数据以键值对（key/value）形式存在**
2. **数据由逗号分隔**
3. **花括号保存对象**（即一个完整的数据）
4. **方括号保存数组**
5. **字符串必须使用双引号**（单引号不合法）
6. **数值不需要引号**
7. **布尔值为 true 或 false（小写）**
8. **空值用 null 表示**

### 两种数据结构

| 结构类型 | 符号 | 说明 |
|---------|------|------|
| 对象（Object） | { } | 无序的 key-value 对集合 |
| 数组（Array） | [ ] | 有序的值集合 |

### 支持的数值类型

- **字符串**：双引号包裹的 Unicode 字符序列，支持转义字符
- **数值**：整数或浮点数，支持科学计数法
- **布尔值**：true / false
- **空值**：null
- **对象**：无序的 string-value 对集合
- **数组**：有序的值集合

### 转义字符

JSON 字符串中支持的转义字符：

| 转义序列 | 含义 |
|---------|------|
| \" | 双引号 |
| \\ | 反斜杠 |
| \/ | 正斜杠（可选转义） |
| \b | 退格 |
| \f | 换页 |
| \n | 换行 |
| \r | 回车 |
| \t | 制表符 |
| \uXXXX | Unicode 字符（4位十六进制） |

## 代码示例

### 基本对象

```json
{
  "name": "张三",
  "age": 28,
  "isStudent": false,
  "score": 95.5
}
```

### 嵌套对象

```json
{
  "user": {
    "id": 1001,
    "name": "李四",
    "address": {
      "city": "北京",
      "district": "朝阳区",
      "zipcode": "100020"
    }
  }
}
```

### 数组

```json
{
  "students": [
    { "name": "王五", "grade": "A" },
    { "name": "赵六", "grade": "B" },
    { "name": "孙七", "grade": "A" }
  ]
}
```

### 复杂嵌套结构

```json
{
  "company": "科技有限",
  "founded": 2015,
  "departments": [
    {
      "name": "研发部",
      "employees": [
        { "id": 1, "name": "Alice", "skills": ["Python", "JavaScript"] },
        { "id": 2, "name": "Bob", "skills": ["Java", "Go"] }
      ]
    },
    {
      "name": "市场部",
      "employees": [
        { "id": 3, "name": "Charlie", "skills": ["SEO", "Content"] }
      ]
    }
  ],
  "active": true,
  "metadata": null
}
```

### 各语言解析示例

**Python**

```python
import json

# 解析 JSON 字符串
data = json.loads('{"name": "Alice", "age": 25}')
print(data["name"])  # Alice

# 转换为 JSON 字符串
print(json.dumps({"name": "Bob", "age": 30}, ensure_ascii=False, indent=2))
```

**JavaScript**

```javascript
const data = JSON.parse('{"name": "Alice", "age": 25}');
console.log(data.name); // Alice

const jsonStr = JSON.stringify({ name: "Bob", age: 30 }, null, 2);
console.log(jsonStr);
```

**Java**

```java
import com.google.gson.Gson;

Gson gson = new Gson();

// 解析 JSON
Map data = gson.fromJson("{\"name\": \"Alice\", \"age\": 25}", Map.class);

// 转换为 JSON
Map<String, Object> map = new HashMap<>();
map.put("name", "Bob");
map.put("age", 30);
String jsonStr = gson.toJson(map);
```

## 应用场景

### 1. Web API 数据交换

JSON 是目前 RESTful API 最主流的数据格式。前后端通过 JSON 进行数据通信：

```
客户端请求 -> 服务器返回 JSON 响应 -> 客户端解析并渲染
```

### 2. 配置文件

许多框架和工具使用 JSON 作为配置文件格式：

- package.json（Node.js 项目）
- tsconfig.json（TypeScript 配置）
- .eslintrc.json（ESLint 配置）
- VS Code 设置文件

### 3. 数据存储

- **MongoDB**：文档存储格式本质上是 BSON（Binary JSON）
- **Redis**：支持 JSON 模块（RedisJSON）
- **Elasticsearch**：文档以 JSON 格式存储和检索

### 4. 跨语言数据交换

JSON 被几乎所有主流编程语言原生支持，是跨平台数据交换的理想选择：

| 语言 | 支持方式 |
|------|---------|
| JavaScript | JSON.parse() / JSON.stringify() |
| Python | json 标准库 |
| Java | Jackson / Gson / JSONObject |
| C# | System.Text.Json / Newtonsoft.Json |
| Go | encoding/json 标准库 |
| Rust | serde_json |
| Ruby | JSON 标准库 |
| PHP | json_decode() / json_encode() |

### 5. 移动开发

- Android：Retrofit + Gson 进行网络请求
- iOS：NSJSONSerialization / Codable
- Flutter：dart:convert 库

## 与 XML 对比

| 对比维度 | JSON | XML |
|---------|------|-----|
| 可读性 | 高，语法简洁 | 中等，标签冗余 |
| 数据大小 | 小，无闭合标签 | 大，标签占用额外空间 |
| 解析速度 | 快 | 较慢 |
| 类型支持 | 原生支持数值、布尔值 | 所有数据均为字符串 |
| 描述能力 | 适合结构化数据 | 适合带文档语义的数据 |
| 扩展性 | 一般 | 强（支持命名空间、属性） |
| 应用场景 | API 数据交换、配置 | 文档标记、企业级协议 |

## 注意事项

### 常见陷阱

1. **字符串必须使用双引号**：{"name": "test"} 合法，{'name': 'test'} 不合法
2. **不允许尾逗号**：[1, 2,] 在严格 JSON 中不合法（虽然许多解析器宽容处理）
3. **键名必须是字符串**：{1: "value"} 不合法，必须是 {"1": "value"}
4. **不允许注释**：标准 JSON 不支持注释（部分扩展格式如 JSON5 支持）
5. **数值格式限制**：NaN、Infinity、-Infinity 不是合法的 JSON 值
6. **函数不能存储在 JSON 中**：JSON 不支持函数、日期等 JavaScript 特殊类型

### 最佳实践

1. **使用有意义的键名**：采用 camelCase 或 snake_case 保持一致性
2. **避免过深的嵌套**：嵌套层级建议不超过 3-4 层，提高可读性
3. **使用数组存储同类数据**：而非重复的键名
4. **API 响应统一包装**：如 {"code": 200, "data": {...}, "message": "success"}
5. **注意字符编码**：确保使用 UTF-8 编码传输
6. **大文件考虑流式解析**：对于超大 JSON 文件，使用流式解析器避免内存溢出

### JSON 验证

在发送或接收 JSON 数据前，建议进行格式验证：

```python
import json

# Python 验证
json_string = '{"name": "test", "age": 25}'
try:
    data = json.loads(json_string)
    print("JSON 格式正确:", data)
except json.JSONDecodeError as e:
    print(f"JSON 解析错误: {e}")
```

## 相关扩展格式

| 格式 | 全称 | 特点 |
|------|------|------|
| JSON5 | JSON 的扩展 | 支持注释、尾逗号、单引号字符串等 |
| JSONC | JSON with Comments | JSON + 注释（VS Code 使用） |
| JSONPath | JSON 的查询语言 | 类似 XPath，用于提取 JSON 中的特定数据 |
| BSON | Binary JSON | JSON 的二进制编码格式，MongoDB 使用 |
| JSON Schema | JSON 的元数据描述 | 用于描述和验证 JSON 数据的结构 |
| JSONP | JSON with Padding | JSON 的跨域请求扩展（已过时） |
| GeoJSON | 地理信息 JSON | 用于编码各种地理数据结构 |

## 相关概念

- [[HTTP]] — JSON 常作为 HTTP API 的响应体格式
- [[RESTful API]] — JSON 是 RESTful API 最常用的数据交换格式
- [[XML]] — JSON 的主要竞争者/替代者
- [[YAML]] — 另一种流行的数据序列化格式，配置文件场景常用
- [[Markdown]] — 另一种轻量级标记语言
- [[JavaScript]] — JSON 源自 JavaScript，语法是其子集
- [[API]] — 应用程序接口，JSON 是其数据交换的核心格式
- [[MongoDB]] — 文档数据库，使用 BSON（JSON 的二进制形式）
- [[JSON Schema]] — 用于定义和验证 JSON 数据结构
- [[序列化与反序列化]] — JSON 解析的本质就是序列化/反序列化过程

## 标签

#编程 #数据格式 #JSON #API #Web开发 #数据交换 #配置文件 #RESTful
