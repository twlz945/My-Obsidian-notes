---
title: Python 网络编程教程
date: 2026-10-02
tags:
  - 网络编程
  - Python
  - 教程
aliases:
  - Python 网络编程
  - Python Networking
related:
  - "[[Socket]]"
  - "[[TCP]]"
  - "[[UDP]]"
  - "[[../网络/Socket入门文档]]"
---

# Python 网络编程教程

从传输层协议到应用层框架，系统梳理用 Python 做网络编程的完整路径：先理解 [[TCP]]/[[UDP]] 与 [[Socket]]，再掌握同步/异步编程，最后接入 HTTP 与 Web 框架。

## 核心要点

- 网络编程的本质是操作**通信端点**（Socket），由 IP + 端口 + 协议唯一确定。
- TCP 面向连接、可靠、字节流；UDP 无连接、低延迟、数据报。
- 同步阻塞模型简单但并发差；高并发优先用 `selectors` / `asyncio`。
- HTTP 建立在 TCP 之上，日常调用优先用 `requests` / `httpx`，而非手写 Socket。
- 生产环境需处理**粘包、超时、编码、优雅关闭、异常边界**。

## 一、前置概念

在写代码之前，先建立协议分层的基本认知：

| 层次 | 代表协议 | Python 中的接触点 |
| ---- | -------- | ----------------- |
| 应用层 | HTTP、WebSocket、DNS、FTP | `requests`、`aiohttp`、`websockets`、[[FastAPI]] |
| 传输层 | [[TCP]]、[[UDP]] | `socket`、`asyncio` |
| 网络层 | IP、ICMP | 一般由内核处理 |
| 链路层 | Ethernet、Wi-Fi | 操作系统与驱动 |

Socket 位于应用层与传输层之间，屏蔽了下层细节。详见 [[Socket]]。

## 二、TCP Socket 编程

### 2.1 服务端基本流程

```python
import socket

# 1. 创建 TCP Socket
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# 允许端口复用，避免异常退出后无法重启
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

# 2. 绑定地址与端口（0.0.0.0 表示监听所有网卡）
server.bind(("0.0.0.0", 8888))

# 3. 开始监听，backlog 为等待队列长度
server.listen(5)
print("服务端已启动，监听 8888 ...")

# 4. 接受连接（阻塞直到有客户端接入）
conn, addr = server.accept()
print(f"客户端已连接: {addr}")

# 5. 收发数据（bytes 类型）
data = conn.recv(1024)
print(f"收到: {data.decode('utf-8')}")
conn.sendall("Hello from server".encode("utf-8"))

# 6. 关闭
conn.close()
server.close()
```

### 2.2 客户端基本流程

```python
import socket

client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client.settimeout(5)  # 设置超时，避免无限阻塞
client.connect(("127.0.0.1", 8888))

client.sendall("Hello from client".encode("utf-8"))
data = client.recv(1024)
print(f"服务端响应: {data.decode('utf-8')}")

client.close()
```

### 2.3 常用方法速查

| 方法 | 说明 |
| ---- | ---- |
| `socket.socket(family, type)` | 创建套接字，`AF_INET` + `SOCK_STREAM`(TCP)/`SOCK_DGRAM`(UDP) |
| `bind((host, port))` | 绑定地址与端口 |
| `listen(backlog)` | 监听连接（仅 TCP 服务端） |
| `accept()` | 返回 `(conn, addr)` |
| `connect((host, port))` | 连接服务端 |
| `recv(bufsize)` / `recvfrom(bufsize)` | 接收数据 |
| `send(data)` / `sendall(data)` | 发送数据，`sendall` 会发送完整数据 |
| `sendto(data, addr)` | UDP 发送到指定地址 |
| `settimeout(sec)` | 设置超时 |
| `setsockopt(...)` | 设置套接字选项 |

> [!warning] `send()` 不保证全部发完
> `send()` 返回实际发送的字节数，可能小于长度；除非明确处理返回值，否则优先用 `sendall()`。

## 三、UDP Socket 编程

UDP 无需连接，直接发送数据报，服务端通常需要 `bind`：

```python
import socket

# 服务端
server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server.bind(("127.0.0.1", 9999))
data, addr = server.recvfrom(4096)
print(f"来自 {addr}: {data.decode('utf-8')}")
server.sendto(b"ack", addr)
```

```python
import socket

# 客户端
client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
client.settimeout(2)
client.sendto(b"hello", ("127.0.0.1", 9999))
try:
    data, server = client.recvfrom(4096)
    print(data.decode("utf-8"))
except socket.timeout:
    print("超时，可能丢包")
```

UDP 无重传、无排序、无拥塞控制，应用层若需要可靠性必须自行实现（如 QUIC）。详见 [[UDP]]。

## 四、并发模型

单线程一次只能处理一个连接，实际服务端需要并发。

### 4.1 多线程

```python
import socket
import threading

def handle(conn, addr):
    with conn:
        while True:
            data = conn.recv(1024)
            if not data:
                break
            conn.sendall(b"Echo: " + data)

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("0.0.0.0", 8888))
server.listen(50)

while True:
    conn, addr = server.accept()
    threading.Thread(target=handle, args=(conn, addr), daemon=True).start()
```

适合连接数几百以内，线程过多会带来上下文切换与内存开销。

### 4.2 I/O 多路复用（selectors）

用单线程管理大量连接，只在有事件时处理：

```python
import selectors
import socket

sel = selectors.DefaultSelector()

def accept(sock):
    conn, addr = sock.accept()
    conn.setblocking(False)
    sel.register(conn, selectors.EVENT_READ, read)

def read(conn):
    data = conn.recv(1024)
    if data:
        conn.sendall(b"Echo: " + data)
    else:
        sel.unregister(conn)
        conn.close()

server = socket.socket()
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("0.0.0.0", 8888))
server.listen(100)
server.setblocking(False)
sel.register(server, selectors.EVENT_READ, accept)

while True:
    for key, _ in sel.select():
        key.data(key.fileobj)
```

`selectors` 会自动在 Linux 下选用 `epoll`、在 macOS 下用 `kqueue`、在 Windows 下用 `select`，是可移植的优选方案。

### 4.3 asyncio 异步

异步模型用单线程 + 事件循环达到高并发，代码接近同步写法：

```python
import asyncio

async def handle(reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
    data = await reader.read(1024)
    writer.write(b"Echo: " + data)
    await writer.drain()
    writer.close()
    await writer.wait_closed()

async def main():
    server = await asyncio.start_server(handle, "0.0.0.0", 8888)
    async with server:
        await server.serve_forever()

asyncio.run(main())
```

| 模型 | 优点 | 缺点 | 适用场景 |
| ---- | ---- | ---- | -------- |
| 同步阻塞 | 简单直观 | 并发差 | 学习、低频工具 |
| 多线程 | 兼容同步代码 | 线程开销、GIL 限制 | 中等并发、CPU 轻负载 |
| `selectors` | 单线程高并发 | 回调式代码较难维护 | 自定义协议服务器 |
| `asyncio` | 高并发、可读性好 | 需全链路异步 | 高并发 I/O 服务 |

## 五、HTTP 网络编程

HTTP 是应用层协议，底层仍是 TCP。理解"用 Socket 手写 HTTP"有助于破除对框架的神秘感：

```python
import socket

client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client.connect(("example.com", 80))
request = (
    "GET / HTTP/1.1\r\n"
    "Host: example.com\r\n"
    "Connection: close\r\n\r\n"
)
client.sendall(request.encode("utf-8"))
response = b""
while chunk := client.recv(4096):
    response += chunk
print(response.decode("utf-8", errors="ignore"))
client.close()
```

实际项目优先使用成熟库：

| 库 | 特点 |
| -- | ---- |
| `urllib` | 标准库，无需安装，API 较底层 |
| `requests` | 同步、简洁，最常用 |
| `httpx` | 同步/异步双支持，HTTP/2 |
| `aiohttp` | 异步客户端与服务端 |

```python
import requests

resp = requests.get("https://httpbin.org/get", timeout=5)
resp.raise_for_status()
print(resp.json())
```

在服务端，直接用 [[FastAPI]] 等框架构建 Web API，比手写 Socket 更安全高效。可参考 [[python/用 Python 搭建复杂项目]] 的组织方式。

## 六、粘包与拆包

TCP 是字节流，没有消息边界，多次 `send` 可能被合并接收，一次 `send` 也可能分多次到达。常见解决方案：

1. **固定长度**：每条消息长度固定，简单但不灵活。
2. **分隔符**：用 `\n` 等分隔，需处理转义。
3. **长度前缀**（推荐）：先发定长头部表明正文长度。

```python
import struct

def send_msg(sock, payload: bytes):
    sock.sendall(struct.pack("!I", len(payload)) + payload)

def recv_exact(sock, n: int) -> bytes:
    buf = b""
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise ConnectionError("连接已关闭")
        buf += chunk
    return buf

def recv_msg(sock) -> bytes:
    (length,) = struct.unpack("!I", recv_exact(sock, 4))
    return recv_exact(sock, length)
```

## 七、常见陷阱与最佳实践

- **始终设置超时**：`settimeout()` 或 `requests` 的 `timeout`，避免永久阻塞。
- **显式处理编码**：Socket 收发的是 `bytes`，统一用 UTF-8 编解码。
- **及时关闭资源**：使用 `with` 或 `try/finally`，防止文件描述符泄漏。
- **端口复用**：服务端设置 `SO_REUSEADDR`，避免重启时端口占用。
- **区分绑定地址**：`127.0.0.1` 仅本机，`0.0.0.0` 监听全部网卡。
- **处理异常边界**：捕获 `ConnectionResetError`、`socket.timeout`、`BrokenPipeError` 等。
- **生产加密**：公网通信使用 TLS/SSL，或直接走 HTTPS。
- **限制资源**：限制并发连接数、单次消息大小与处理时间，防止被拖垮。

## 八、推荐学习路线

| 阶段 | 内容 | 练习 |
| ---- | ---- | ---- |
| 1 | Socket API、TCP 客户端/服务端 | 回声服务器 |
| 2 | UDP、多线程并发 | 多客户端聊天室 |
| 3 | 超时、异常、粘包处理 | 文件传输工具 |
| 4 | `selectors` / `asyncio` | 异步高并发服务器 |
| 5 | HTTP、WebSocket、Web 框架 | REST API 服务 |

可对照 [[Python进阶阶段学习规划表]] 的"数据库与网络"部分安排进度。

## 九、调试工具

```bash
# 查看端口占用
netstat -ano | findstr 8888      # Windows
lsof -i :8888                    # macOS / Linux

# 测试连通性
nc -zv 127.0.0.1 8888            # netcat
telnet 127.0.0.1 8888

# 抓包分析
# Wireshark：图形化查看 TCP/UDP 原始报文
```

## 相关笔记

- [[../网络/Socket入门文档]] — Socket 编程实战教程
- [[Socket]] — 套接字概念与 API
- [[TCP]] — 面向连接的可靠传输协议
- [[UDP]] — 无连接的数据报协议
- [[FastAPI]] — Python Web 框架
- [[python/用 Python 搭建复杂项目]] — Python 工程化
- [[Python进阶阶段学习规划表]] — 学习路线

## 参考来源

- [Python 官方文档 — socket](https://docs.python.org/3/library/socket.html)
- [Python 官方文档 — asyncio](https://docs.python.org/3/library/asyncio.html)
- [Python 官方文档 — selectors](https://docs.python.org/3/library/selectors.html)
- [Requests 官方文档](https://requests.readthedocs.io/)
