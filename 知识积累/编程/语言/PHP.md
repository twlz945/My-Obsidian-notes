---
title: PHP
date: 2026-10-02
tags:
  - 后端开发
  - PHP
  - Web开发
aliases:
  - PHP: Hypertext Preprocessor
related:
  - "[[../教程/前端/PHP入门文档]]"
  - "[[后端]]"
  - "[[MySQL]]"
  - "[[API]]"
---

# PHP
> “PHP 是世界上最好的编程语言”

PHP（PHP: Hypertext Preprocessor，递归缩写）是一门主要面向 Web 的通用脚本语言。它运行在服务端，可嵌入 HTML，请求到来时由解释器执行并生成页面或接口响应。至今仍是 WordPress、Laravel 等大量网站与服务端系统的实现语言。

## 核心要点

- **为 Web 而生**：原生处理表单、Cookie、Session、HTTP 头与数据库，零额外框架即可写出动态页面。
- **弱类型 + 动态类型**：变量以 `$` 开头，类型随值变化，运行时自动转换（也是常见坑来源）。
- **请求即生命周期**：传统模式下每次请求都重新初始化，全局状态不跨请求保留（区别于常驻进程的 [[Node.js]]）。
- **数组是瑞士军刀**：`array` 同时充当列表、字典、栈、队列，是 PHP 使用频率最高的结构。
- **生态成熟**：Composer 包管理 + Laravel / Symfony 框架 + WordPress 建站，存量项目与招聘需求多。

## 语言特性

### 变量与类型

```php
<?php
$name = "Ada";     // 字符串
$age = 36;         // 整数
$price = 9.9;      // 浮点
$tags = ["php", "web"];                    // 数组（列表）
$user = ["name" => "Ada", "age" => 36];    // 关联数组（字典）

var_dump($age);          // 查看类型与值
echo gettype($price);    // double
```

标量类型：`bool`、`int`、`float`、`string`；复合类型：`array`、`object`；特殊：`null`、`resource`、`callable`。

### 弱类型与类型声明

```php
var_dump("1" + 2);        // int(3)，自动转换
var_dump(0 == "abc");     // PHP 7 为 true；PHP 8 起比较语义修正为 false

function add(int $a, int $b): int {   // 现代 PHP 支持参数/返回类型声明
    return $a + $b;
}
```

> [!warning] 用 `==` 比较时存在隐式转换，优先使用 `===` / `!==` 做严格比较，可避免大量「魔术行为」。

### 超全局变量

| 变量 | 用途 |
| ---- | ---- |
| `$_GET` | URL 查询参数 |
| `$_POST` | 表单 POST 数据 |
| `$_SERVER` | 请求方法、路径、请求头等 |
| `$_SESSION` | 会话数据（需 `session_start()`） |
| `$_COOKIE` | 客户端 Cookie |
| `$_FILES` | 上传文件 |

## 运行原理

PHP 通常作为 **FPM / mod_php** 模块挂在 Nginx/Apache 后面，执行流程大致为：

```text
浏览器请求 → Web 服务器 → PHP-FPM 进程池 → Zend 引擎编译执行脚本 → 输出 HTML/JSON → 返回浏览器
```

- **Zend 引擎**：把源码编译成 opcode 再执行，OPcache 可缓存 opcode 提速。
- **请求隔离**：每个请求独立执行，用完即释放（除非使用 Swoole / RoadRunner 等常驻内存运行时）。
- **开发内置服务器**：`php -S localhost:8000` 无需 Nginx 即可起服务，适合本地调试。

## 语法速览

```php
<?php
// 流程控制
if ($age >= 18) {
    echo "成年";
} elseif ($age > 0) {
    echo "未成年";
} else {
    echo "年龄异常";
}

// 循环与数组
$fruits = ["apple", "banana", "cherry"];
foreach ($fruits as $index => $fruit) {
    echo "$index: $fruit\n";
}

$user = ["name" => "Ada", "age" => 36];
foreach ($user as $key => $value) {
    echo "$key = $value\n";
}
```

## 数据库与网络

- **PDO**：统一的数据库访问层，支持 MySQL、PostgreSQL、SQLite 等；**务必使用预处理语句**防 SQL 注入。

```php
<?php
$pdo = new PDO("mysql:host=localhost;dbname=app;charset=utf8mb4", "user", "pass", [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]);

$stmt = $pdo->prepare("SELECT id, name FROM users WHERE age > :age");
$stmt->execute(["age" => 18]);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

header("Content-Type: application/json; charset=utf-8");
echo json_encode($rows);   // 返回 [[JSON]]
```

相关数据库笔记见 [[MySQL]]。

## 包管理与框架

| 工具 / 框架 | 定位 | 说明 |
| ----------- | ---- | ---- |
| Composer | 依赖管理 | PHP 版 npm，`composer.json` 描述依赖 |
| Laravel | 全栈框架 | 生态最全，自带 ORM（Eloquent）、模板、队列 |
| Symfony | 组件化框架 | 组件被 Laravel 等大量复用，企业级常用 |
| Slim | 微框架 | 适合小型 [[API]] 服务 |
| WordPress | CMS | 全球占比极高的建站系统，插件生态庞大 |

## 与其它后端语言对比

| 维度 | PHP | [[Node.js]] | Python（[[FastAPI]] / [[Flask]]） |
| ---- | --- | ----------- | --------------------------------- |
| 执行模式 | 请求级解释执行（FPM） | 常驻事件循环 | 常驻（同步 / 异步） |
| 上手难度 | 低，环境即可写页面 | 中，需懂异步 | 低，语法直观 |
| 典型场景 | 建站、CMS、传统 Web | 实时通信、BFF、[[API]] 网关 | 数据、AI、通用后端 |
| 包管理 | Composer | npm / pnpm | pip / uv / poetry |
| 优势 | 部署简单、存量生态大 | 全栈同语言、I/O 密集强 | 生态与可读性均衡 |

## 常见坑

| 现象 | 原因 | 建议 |
| ---- | ---- | ---- |
| `0 == "abc"` 结果反直觉 | 弱类型隐式转换 | 用 `===` 严格比较 |
| 浮点金额出现误差 | 二进制浮点精度 | 金额用整数分存储或 `bcmath` |
| SQL 注入 | 拼接用户输入进 SQL | 使用 PDO 预处理语句 |
| 中文乱码 | 编码不一致 | 统一 UTF-8，连接串加 `charset=utf8mb4` |
| 报「headers already sent」 | 输出后才调用 `header()` | 在输出任何内容前发送响应头 |
| 状态没跨请求保留 | 误以为进程常驻 | 记住请求级生命周期，跨请求用 Session |

## 相关笔记

- [[../教程/前端/PHP入门文档]] — 零基础环境搭建与语法实战
- [[后端]] — 后端开发目录导航
- [[MySQL]] — PHP 最常搭配的关系型数据库
- [[API]] — 用 PHP 提供 RESTful 接口
- [[JSON]] — `json_encode()` / `json_decode()` 数据交换
- [[Node.js]] — 另一种主流 Web 后端运行时
- [[编程]] — 编程知识目录导航

## 参考来源

- [PHP 官方手册（中文）](https://www.php.net/manual/zh/)
- [Composer 官方文档](https://getcomposer.org/doc/)
- [Laravel 中文文档](https://laravel.com/docs)
