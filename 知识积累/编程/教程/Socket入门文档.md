---
title: Socket 入门文档
date: 2026-10-01
tags:
  - 网络编程
  - Socket
  - 教程
---
# Socket 入门文档

## 一、Socket 是什么

[[Socket]]（套接字）是网络编程的抽象层接口，它把复杂的 TCP/IP 协议族隐藏在后面的 API 里面，对于程序员来说，进行网络编程只要用到 Socket 就可以了。

可以把 Socket 理解为两个程序之间的"通信管道"：一个程序在管道的一端写入数据，另一个程序在另一端读取数据。

### 核心概念

| 概念 | 说明 |
|------|------|
| IP 地址 | 网络中设备的唯一标识，如 127.0.0.1（本地回环地址） |
| 端口号 | 设备中进程的标识，范围 0~65535，常用端口如 80(HTTP)、443(HTTPS) |
| TCP | 面向连接的可靠传输协议，保证数据不丢失、不重复、按序到达 |
| UDP | 面向无连接的不可靠传输协议，速度快但不保证到达 |
| Socket | 通信端点，封装了 IP 地址和端口号，是 TCP/UDP 编程的接口 |

---

## 二、Socket 通信模型

### [[TCP]] 三次握手

```
客户端                          服务端
  |--- SYN (seq=x) ----------->|
  |<-- SYN+ACK (seq=y,ack=x+1) |
  |--- ACK (ack=y+1) ---------->|
  |         连接建立            |
```

### [[UDP]] 通信流程

UDP 不需要握手建立连接，客户端直接发送数据报，服务端直接接收，过程简单但不可靠。

---

## 三、Python Socket 基础 API

### 创建 Socket

```python
import socket

# AF_INET 表示 IPv4 网络
# SOCK_STREAM 表示 TCP 协议
# SOCK_DGRAM 表示 UDP 协议
tcp_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
```

### TCP 服务端常用方法

| 方法 | 说明 |
|------|------|
| bind(address) | 绑定 IP 地址和端口号 |
| listen(backlog) | 启动监听，backlog 为最大连接等待数 |
| accept() | 阻塞等待客户端连接，返回 (conn, addr) |
| recv(bufsize) | 接收数据，返回 bytes |
| send(data) / sendall(data) | 发送数据 |
| close() | 关闭连接 |

### TCP 客户端常用方法

| 方法 | 说明 |
|------|------|
| connect(address) | 连接服务端 |
| recv(bufsize) | 接收数据 |
| send(data) / sendall(data) | 发送数据 |
| close() | 关闭连接 |

### UDP 常用方法

| 方法 | 说明 |
|------|------|
| bind(address) | 绑定地址（服务端） |
| sendto(data, address) | 发送数据到指定地址 |
| recvfrom(bufsize) | 接收数据，返回 (data, address) |

---

## 四、TCP 编程实战

### 4.1 简单 TCP 服务端

```python
import socket

# 1. 创建 Socket
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# 2. 绑定地址和端口
server.bind(('127.0.0.1', 8888))

# 3. 监听连接
server.listen(5)
print('服务端已启动，监听端口 8888...')

# 4. 接受客户端连接
conn, addr = server.accept()
print(f'客户端已连接: {addr}')

# 5. 接收数据
data = conn.recv(1024)
print(f'收到数据: {data.decode("utf-8")}')

# 6. 发送响应
conn.sendall('Hello from server!'.encode('utf-8'))

# 7. 关闭连接
conn.close()
server.close()
```

### 4.2 简单 TCP 客户端

```python
import socket

# 1. 创建 Socket
client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# 2. 连接服务端
client.connect(('127.0.0.1', 8888))

# 3. 发送数据
client.sendall('Hello from client!'.encode('utf-8'))

# 4. 接收响应
data = client.recv(1024)
print(f'收到服务端响应: {data.decode("utf-8")}')

# 5. 关闭连接
client.close()
```

### 4.3 循环服务端（支持多次通信）

```python
import socket

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind(('127.0.0.1', 8888))
server.listen(5)
print('服务端已启动...')

while True:
    conn, addr = server.accept()
    print(f'客户端已连接: {addr}')
    
    while True:
        data = conn.recv(1024)
        if not data:  # 客户端断开连接
            print(f'客户端 {addr} 已断开')
            break
        print(f'收到: {data.decode("utf-8")}')
        response = input('服务端回复: ')
        conn.sendall(response.encode('utf-8'))
    
    conn.close()
```

---

## 五、UDP 编程实战

### 5.1 UDP 服务端

```python
import socket

server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server.bind(('127.0.0.1', 9999))
print('UDP服务端已启动，监听端口 9999...')

while True:
    data, addr = server.recvfrom(1024)
    print(f'收到来自 {addr} 的数据: {data.decode("utf-8")}')
    
    response = input('回复: ')
    server.sendto(response.encode('utf-8'), addr)
```

### 5.2 UDP 客户端

```python
import socket

client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
server_addr = ('127.0.0.1', 9999)

message = 'Hello UDP Server!'
client.sendto(message.encode('utf-8'), server_addr)

data, addr = client.recvfrom(1024)
print(f'收到服务端响应: {data.decode("utf-8")}')

client.close()
```

---

## 六、多线程并发服务端

单线程服务端一次只能处理一个客户端连接，使用多线程可以同时服务多个客户端：

```python
import socket
import threading

def handle_client(conn, addr):
    """处理单个客户端的通信"""
    print(f'新连接: {addr}')
    try:
        while True:
            data = conn.recv(1024)
            if not data:
                break
            print(f'{addr} 发送: {data.decode("utf-8")}')
            conn.sendall(f'Echo: {data.decode("utf-8")}'.encode('utf-8'))
    except ConnectionResetError:
        pass
    finally:
        conn.close()
        print(f'连接关闭: {addr}')

# 创建服务端 Socket
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind(('0.0.0.0', 8888))
server.listen(5)
print('多线程服务端已启动...')

while True:
    conn, addr = server.accept()
    # 为每个客户端创建独立线程
    thread = threading.Thread(target=handle_client, args=(conn, addr))
    thread.start()
```

---

## 七、常见陷阱与注意事项

### 7.1 编码问题

Socket 传输的是字节流（bytes），字符串必须先编码，接收后必须解码：

```python
# 发送前编码
conn.sendall('你好'.encode('utf-8'))

# 接收后解码
data = conn.recv(1024).decode('utf-8')
```

### 7.2 粘包与拆包

TCP 是流式协议，多次 send 的数据可能一次性到达（粘包），一次 send 的数据可能分多次到达（拆包）。解决方法：

- 自定义应用层协议（如固定头部长度 + 消息体）
- 使用分隔符（如换行符）分割消息
- 先发送消息长度，再发送消息体

### 7.3 阻塞与非阻塞

默认情况下 Socket 操作是阻塞的，可以使用 settimeout() 设置超时：

```python
server.settimeout(10)  # 10秒超时
try:
    data = server.recv(1024)
except socket.timeout:
    print('接收超时')
```

### 7.4 端口与地址

| 绑定地址 | 说明 |
|----------|------|
| 127.0.0.1 | 仅本机可访问（回环地址） |
| 0.0.0.0 | 监听所有网卡，允许外部连接 |
| localhost | 等同于 127.0.0.1 |

### 7.5 优雅关闭

```python
# 服务端关闭
server.shutdown(socket.SHUT_RDWR)  # 禁止新的收发
server.close()

# 客户端关闭
client.close()
```

---

## 八、Socket 与 HTTP 的关系

HTTP 协议是基于 TCP 的的应用层协议。用 Socket 可以手动实现一个简单的 HTTP 客户端：

```python
import socket

# 手动发送 HTTP 请求
client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client.connect(('www.baidu.com', 80))

request = 'GET / HTTP/1.1\r\nHost: www.baidu.com\r\n\r\n'
client.sendall(request.encode('utf-8'))

response = b''
while True:
    data = client.recv(4096)
    if not data:
        break
    response += data
    if len(data) < 4096:
        break

print(response.decode('utf-8', errors='ignore')[:2000])
client.close()
```

> 实际项目中推荐使用 requests 库代替手动 Socket 编程来处理 HTTP 请求，更加简洁安全。

---

## 九、学习路线建议

| 阶段 | 学习内容 | 练习项目 |
|------|----------|----------|
| 第一阶段 | Socket 基础 API、TCP 客户端/服务端 | 回声服务器 |
| 第二阶段 | UDP 编程、多线程并发 | 多客户端聊天室 |
| 第三阶段 | 异常处理、超时控制、粘包处理 | 文件传输工具 |
| 第四阶段 | asyncio 异步编程、aiohttp | 异步高并发服务器 |
| 第五阶段 | WebSocket、HTTP 框架 | 实时聊天应用 |

---

## 十、常用调试命令

```bash
# 查看端口占用
netstat -ano | findstr 8888          # Windows
lsof -i :8888                         # macOS/Linux

# 测试 TCP 连接
telnet 127.0.0.1 8888                 # 传统方式
nc -zv 127.0.0.1 8888                 # netcat（Linux/macOS）

# 查看本机所有监听端口
netstat -an | findstr LISTENING       # Windows
ss -tulpn                             # Linux

# Wireshark 抓包分析（图形化工具）
# 下载 Wireshark 后可实时查看 Socket 通信的原始数据包
```

---
#编程 #网络编程 #Socket #教程