---
title: PHP 入门文档
date: 2026-10-02
tags:
  - PHP
  - 后端开发
  - 教程
aliases:
  - PHP入门
  - PHP基础
related:
  - "[[PHP]]"
  - "[[前端/HTML入门文档]]"
  - "[[MySQL]]"
  - "[[API]]"
  - "[[后端]]"
---

# PHP 入门文档

PHP 是运行在服务端的脚本语言，最经典的用途是把 [[前端/HTML入门文档|HTML]] 变成「动态页面」：接收表单、读写数据库、返回内容。本篇面向零基础，从环境搭建到写出一个可交互的小站点；语言机制的系统整理见 [[PHP]]。

## 核心要点

- **代码跑在服务器**：浏览器只拿到最终 HTML / [[JSON]]，看不到 PHP 源码。
- **变量以 `$` 开头**，动态弱类型，写起来快但要用 `===` 防坑。
- **嵌入 HTML**：`<?php ... ?>` 标签内写逻辑，标签外写页面结构。
- **数组极强**：列表和字典都用 `array`，`foreach` 是日常主力。
- **反馈快**：`php -S` 一行命令就能起本地服务。

## 一、环境搭建

### 方式 A：直接装 PHP（推荐用于学习）

```bash
# Windows 可用 winget / 官网 zip；macOS 用 Homebrew；Linux 用包管理器
php -v                      # 确认安装成功

# 启动内置开发服务器，当前目录作为站点根
php -S localhost:8000
```

### 方式 B：集成环境 / 容器

- **XAMPP / Laragon**：一键安装 Apache + PHP + MySQL，适合 Windows 新手。
- **Docker**：使用官方 `php` 镜像，环境可复现，适合团队。

> [!tip] 学习阶段优先用 `php -S` 或 Laragon，省去配置 Nginx / FPM 的精力。

## 二、第一个程序

新建 `hello.php`：

```php
<?php
echo "Hello, PHP!";
```

访问 `http://localhost:8000/hello.php`，页面输出 `Hello, PHP!`。

与 HTML 混写：

```php
<!DOCTYPE html>
<html lang="zh-CN">
<body>
  <h1><?php echo "现在时间：" . date("Y-m-d H:i:s"); ?></h1>
</body>
</html>
```

## 三、变量与数据类型

```php
<?php
$name = "Ada";        // string
$age = 36;            // int
$price = 9.9;         // float
$isMember = true;     // bool
$nothing = null;      // null

echo "姓名：$name，年龄：$age";   // 双引号内可直接插值
echo '年龄：$age';                // 单引号不解析变量，原样输出

var_dump($price);       // float(9.9)
gettype($name);         // "string"
(int) "42";             // 强制类型转换
```

字符串拼接用 `.`：

```php
$full = $name . " - " . $age;
```

## 四、运算符与流程控制

```php
<?php
// 严格比较（推荐）
1 === 1;      // true
"1" === 1;    // false

if ($age >= 18) {
    echo "成年";
} elseif ($age > 0) {
    echo "未成年";
} else {
    echo "年龄异常";
}

for ($i = 0; $i < 3; $i++) {
    echo $i;
}

$i = 0;
while ($i < 3) {
    echo $i++;
}
```

三元与空合并：

```php
$label = $isMember ? "会员" : "游客";
$nickname = $userInput ?? "匿名";   // null 时取默认值
```

## 五、数组

```php
<?php
// 索引数组（列表）
$fruits = ["apple", "banana", "cherry"];
echo $fruits[0];              // apple
$fruits[] = "date";           // 追加

// 关联数组（字典）
$user = ["name" => "Ada", "age" => 36];
echo $user["name"];           // Ada

// 遍历
foreach ($fruits as $fruit) {
    echo $fruit;
}
foreach ($user as $key => $value) {
    echo "$key = $value";
}

// 常用函数
count($fruits);               // 元素个数
in_array("apple", $fruits);   // 是否存在
array_keys($user);            // ["name", "age"]
array_map(fn($f) => strtoupper($f), $fruits);
```

## 六、函数

```php
<?php
function add(int $a, int $b): int {
    return $a + $b;
}

function greet(string $name = "world"): string {
    return "Hello, $name!";
}

echo add(1, 2);          // 3
echo greet();            // Hello, world!

// 匿名函数 / 箭头函数
$double = fn($n) => $n * 2;
echo $double(5);         // 10
```

## 七、表单与超全局变量

```php
<?php
// form.php：处理表单提交
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $username = trim($_POST["username"] ?? "");
    if ($username === "") {
        echo "用户名不能为空";
    } else {
        echo "欢迎，" . htmlspecialchars($username);   // 防 XSS
    }
}
?>

<form method="post" action="form.php">
  <input type="text" name="username" placeholder="输入名字">
  <button type="submit">提交</button>
</form>
```

| 超全局变量 | 说明 |
| ---------- | ---- |
| `$_GET` | URL 查询参数，如 `?id=1` |
| `$_POST` | POST 表单数据 |
| `$_SERVER` | 请求方法、路径、来源等 |
| `$_SESSION` | 会话，需先 `session_start()` |
| `$_FILES` | 上传文件信息 |

> [!warning] 任何用户输入都不可信：输出用 `htmlspecialchars()` 转义，入数据库用预处理语句。

## 八、连接数据库（PDO）

以 [[MySQL]] 为例：

```php
<?php
$pdo = new PDO(
    "mysql:host=localhost;dbname=app;charset=utf8mb4",
    "user",
    "password",
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

// 预处理，防 SQL 注入
$stmt = $pdo->prepare("SELECT id, name FROM users WHERE age > :age");
$stmt->execute(["age" => 18]);
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);

header("Content-Type: application/json; charset=utf-8");
echo json_encode($users);      // 输出 [[JSON]]，可作为 [[API]] 响应
```

## 九、面向对象与 Composer

```php
<?php
class User
{
    public function __construct(
        private string $name,
        private int $age,
    ) {}

    public function intro(): string
    {
        return "{$this->name}，{$this->age} 岁";
    }
}

$user = new User("Ada", 36);
echo $user->intro();
```

用 Composer 管理依赖与自动加载：

```bash
composer init                        # 生成 composer.json
composer require guzzlehttp/guzzle   # 安装 HTTP 客户端
composer dump-autoload               # 重新生成自动加载
```

```php
<?php
require __DIR__ . "/vendor/autoload.php";
// 之后即可使用已安装的第三方类库
```

## 十、常见坑

| 现象 | 原因 | 建议 |
| ---- | ---- | ---- |
| `0 == "abc"` 为真 | 弱类型隐式转换 | 一律用 `===` / `!==` |
| 页面报 headers already sent | `header()` 前已有输出 | 响应头要在任何输出之前发送 |
| 中文乱码 | 编码不统一 | 全链路 UTF-8，连接串加 `charset=utf8mb4` |
| 表单看不到 `$_POST` | 表单没写 `method="post"` | 检查 method 与 name 属性 |
| SQL 注入 | 拼接用户输入 | 使用 PDO 预处理语句 |
| 金额计算有小数误差 | 浮点精度 | 用整数分或 `bcmath` / `gmp` |

## 十一、学习路线与练习

| 阶段 | 内容 | 练习 |
| ---- | ---- | ---- |
| 入门 | 变量、流程、函数 | 猜数字、成绩判断 |
| 基础 | 数组与表单 | 待办清单（Session 存储） |
| 进阶 | PDO 与数据库 | 用户注册 / 登录 |
| 实战 | OOP 与 Composer | 用 Laravel 写一个小型 [[API]] |
| 综合 | 安全与部署 | 加 CSRF 防护并部署到服务器 |

## 相关笔记

- [[PHP]] — 语言特性与生态的系统参考
- [[前端/HTML入门文档]] — PHP 常与之配合生成动态页面
- [[MySQL]] — 用 PDO 读写数据
- [[API]] — 用 PHP 提供接口
- [[JSON]] — 前后端数据交换格式
- [[后端]] — 后端开发目录导航
- [[编程]] — 编程知识目录导航

## 参考来源

- [PHP 官方手册（中文）](https://www.php.net/manual/zh/)
- [PHP: The Right Way](https://phptherightway.com/)
- [Laravel 中文文档](https://laravel.com/docs)
