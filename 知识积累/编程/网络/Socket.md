## 核心定义

**** 是网络通信中的**通信端点**，也是应用程序访问网络协议栈的入口。

一个 Socket 通常由以下要素共同确定：

|要素|作用|
|---|---|
|**IP 地址**|定位网络中的主机|
|**端口号**|定位主机上的具体进程|
|**协议**|决定数据传输方式，如 TCP 或 UDP|

[[TCP]] 连接通常可以用一个四元组唯一标识：

```text
{源IP, 源端口, 目的IP, 目的端口}
```

在 Linux/Unix 系统中，Socket 通常表现为一个**文件描述符**，因此可以像文件一样进行读写操作。

---

## 工作原理

Socket 位于应用层和传输层之间，屏蔽了底层网络协议细节。

应用程序不需要直接处理 IP 包构造、分片、重传、校验和等问题，只需要通过 Socket API 完成以下操作：

```text
创建 Socket
  ↓
绑定地址和端口（服务端常见）
  ↓
监听连接（TCP 服务端）
  ↓
建立连接
  ↓
发送 / 接收数据
  ↓
关闭 Socket
```

内核会维护发送缓冲区和接收缓冲区，负责数据的封装、传输、排序和交付。

---

## 主要类型

|类型|对应协议|特点|
|---|---|---|
|**SOCK_STREAM**|TCP|面向连接、可靠、有序、字节流|
|**SOCK_DGRAM**|UDP|无连接、不可靠、低延迟、数据报|
|**SOCK_RAW**|原始协议|可访问 IP 层数据包，用于网络诊断或协议开发|

---

## TCP 与 UDP 对比

|维度|TCP|UDP|
|---|---|---|
|连接方式|面向连接|无连接|
|可靠性|可靠传输|不保证可靠|
|数据形式|字节流|数据报|
|顺序保证|有序|不保证顺序|
|延迟|相对较高|较低|
|适用场景|Web、文件传输、邮件、数据库|实时音视频、游戏、DNS、直播|

TCP 通过三次握手建立连接，通过四次挥手断开连接；UDP 没有连接建立和断开过程。

---

## 常用 API

### 服务端流程（TCP）

```text
socket()      // 创建套接字
bind()        // 绑定 IP 和端口
listen()      // 开始监听
accept()      // 接受客户端连接
recv()/send() // 收发数据
close()       // 关闭连接
```

### 客户端流程（TCP）

```text
socket()      // 创建套接字
connect()     // 连接服务端
send()/recv() // 收发数据
close()       // 关闭连接
```

### UDP 常用操作

UDP 通常不需要 `listen()` 和 `accept()`，而是直接使用：

```text
socket()
bind()       // 服务端通常需要绑定
sendto()
recvfrom()
close()
```

---

## 代码示例

### Python TCP 服务端

```python
import socket

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind(("127.0.0.1", 8080))
server.listen(5)

print("等待客户端连接...")
conn, addr = server.accept()
print(f"客户端已连接: {addr}")

data = conn.recv(1024)
print(f"收到数据: {data.decode()}")

conn.send(b"Hello from server")
conn.close()
server.close()
```

### Python TCP 客户端

```python
import socket

client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client.connect(("127.0.0.1", 8080))

client.send(b"Hello from client")
data = client.recv(1024)
print(f"收到服务端响应: {data.decode()}")

client.close()
```

### Python UDP 示例

```python
import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.sendto(b"Hello UDP", ("127.0.0.1", 9090))

data, addr = sock.recvfrom(1024)
print(f"收到数据: {data.decode()}, 来自: {addr}")

sock.close()
```

---

## 通信流程

### TCP 连接建立

TCP 通信前需要建立连接，过程通常称为**三次握手**：

```text
客户端 → SYN → 服务端
客户端 ← SYN+ACK ← 服务端
客户端 → ACK → 服务端
```

连接建立后，双方可以进行双向数据传输。

### TCP 连接断开

通信结束后，通过**四次挥手**释放连接：

```text
主动方 → FIN → 被动方
主动方 ← ACK ← 被动方
主动方 ← FIN ← 被动方
主动方 → ACK → 被动方
```

---

## 阻塞与非阻塞

Socket 可以工作在两种模式下：

|模式|行为|
|---|---|
|**阻塞模式**|调用 `recv()`、`accept()` 等函数时，线程会等待直到操作完成|
|**非阻塞模式**|调用后立即返回，即使数据尚未就绪，程序需要自行处理未完成状态|

阻塞模式编程简单，但并发能力受限；非阻塞模式适合高并发场景，但编程复杂度更高。

---

## I/O 多路复用

当服务器需要同时处理大量连接时，不能为每个连接都创建一个线程，否则会产生严重的资源开销。

I/O 多路复用允许一个线程同时监控多个 Socket 的状态，只在有事件发生时才进行处理。

|机制|特点|
|---|---|
|**select**|早期方案，有文件描述符数量限制，时间复杂度 O(n)|
|**poll**|去除了数量限制，但仍需遍历所有描述符，时间复杂度 O(n)|
|**epoll**|Linux 高性能方案，基于事件通知，时间复杂度接近 O(1)，适合高并发|

epoll 是 Linux 下高并发网络服务的常用底层机制，Nginx、Redis 等都依赖它处理大量连接。

---

## 常见问题

### 粘包问题

TCP 是面向字节流的协议，没有天然的消息边界。多次发送的数据可能被合并接收，或者一次发送的数据被拆分接收。

常见解决方案：

- 固定长度包
- 消息头 + 消息体，消息头中携带长度
- 使用分隔符

### 端口占用

如果程序异常退出，端口可能仍处于占用状态。可以设置：

```python
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
```

### 连接泄漏

Socket 使用完成后必须关闭，否则会导致文件描述符泄漏，最终可能无法创建新的连接。

---

## 应用场景

|场景|说明|
|---|---|
|**Web 服务**|HTTP/HTTPS 基于 TCP Socket|
|**即时通讯**|聊天软件通过长连接推送消息|
|**在线游戏**|实时交互常使用 UDP 或自定义协议|
|**文件传输**|FTP、SCP 等基于 TCP|
|**数据库通信**|客户端与数据库服务器通过 Socket 交互|
|**物联网**|设备上报数据常使用 MQTT over TCP|
|**实时音视频**|视频会议、直播多使用 UDP 或 QUIC|

---

## 注意事项

- 服务端通常需要绑定固定端口，客户端端口可由系统自动分配
- TCP 适合可靠性要求高的场景，UDP 适合实时性要求高的场景
- 生产环境建议使用 TLS/SSL 加密通信
- 高并发服务应优先考虑 I/O 多路复用，而不是每连接一线程
- 关闭 Socket 时应正确处理异常，避免资源泄漏
- epoll 是 Linux 特有机制，跨平台项目需要考虑 select、poll 或 IOCP

---

## 相关概念

-

-

-

-

-

-

-

-

-

-

---

#网络编程 #Socket #TCP #UDP #IO多路复用 #epoll #操作系统 #后端开发 #分布式系统 #通信协议