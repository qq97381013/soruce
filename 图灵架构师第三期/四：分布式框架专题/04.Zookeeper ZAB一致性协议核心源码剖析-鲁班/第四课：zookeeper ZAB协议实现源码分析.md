**课程概要：**

1. 启动流程源码分析
2. 快照与事物日志的存储结构
## 一、启动流程

---
**知识点：**

1. 工程结构介绍
2. 启动流程宏观图
3. 集群启动详细流程
4. netty 服务工作机制
### 1.工程结构介绍
项目地址:[https://github.com/apache/zookeeper.git](https://github.com/apache/zookeeper.git)

分支tag ：3.5.5

* zookeeper-recipes: 示例源码
* zookeeper-client: C语言客户端
* zookeeper-server：主体源码
### **2.启动宏观流程图：**
![图片](https://uploader.shimo.im/f/jMRsPEAEi4EeYUO4.png!thumbnail)

- [ ] 启动示例演示：

**服务端：**ZooKeeperServerMain

**客户端：**ZooKeeperMain

### 3.集群启动详细流程
装载配置：

```
# zookeeper 启动流程堆栈
 >QuorumPeerMain#initializeAndRun //启动工程 
   >QuorumPeerConfig#parse // 加载config 配置
    >QuorumPeerConfig#parseProperties// 解析config配置
 >new DatadirCleanupManager // 构造一个数据清器
  >DatadirCleanupManager#start // 启动定时任务 清除过期的快照
```



**代码堆栈 ：**

```
>QuorumPeerMain#main  //启动main方法
 >QuorumPeerConfig#parse // 加载zoo.cfg 文件
   >QuorumPeerConfig#parseProperties // 解析配置
 >DatadirCleanupManager#start // 启动定时任务清除日志
 >QuorumPeerConfig#isDistributed // 判断是否为集群模式
  >ServerCnxnFactory#createFactory() // 创建服务默认为NIO，推荐netty
 //***创建 初始化集群管理器**/
 >QuorumPeerMain#getQuorumPeer
 >QuorumPeer#setTxnFactory 
 >new FileTxnSnapLog // 数据文件管理器，用于检测快照与日志文件
   /**  初始化数据库*/
  >new ZKDatabase 
    >ZKDatabase#createDataTree //创建数据树，所有的节点都会存储在这
 // 启动集群：同时启动线程
  > QuorumPeer#start // 
    > QuorumPeer#loadDataBase // 从快照文件以及日志文件 加载节点并填充到dataTree中去
    > QuorumPeer#startServerCnxnFactory // 启动netty 或java nio 服务，对外开放2181 端口
    > AdminServer#start// 启动管理服务，netty http服务，默认端口是8080
    > QuorumPeer#startLeaderElection // 开始执行选举流程
    > quorumPeer.join()  // 防止主进程退出 
```
**流程说明:**

1.   main方法启动
  1. 加载zoo.cfg  配置文件
  2. 解析配置
  3. 创建服务工厂
  4. 创建集群管理线程
    1. 设置数据库文件管理器
    2. 设置数据库
    3. ....设置设置
  5. start启动集群管理线程
    1. 加载数据节点至内存
    2. 启动netty 服务，对客户端开放端口
    3. 启动管理员Http服务，默认8080端口
    4. 启动选举流程
  6. join 管理线程，防止main 进程退出

### 4.netty 服务启动流程：
服务UML类图

![图片](https://uploader.shimo.im/f/EcKT09vDArApxofJ.png!thumbnail)

设置netty启动参数

```
-Dzookeeper.serverCnxnFactory=org.apache.zookeeper.server.NettyServerCnxnFactory
```
**初始化：**

关键代码：

```
#初始化管道流 
#channelHandler 是一个内部类是具体的消息处理器。
protected void initChannel(SocketChannel ch) throws Exception {
    ChannelPipeline pipeline = ch.pipeline();
    if (secure) {
        initSSL(pipeline);
    }
    pipeline.addLast("servercnxnfactory", channelHandler);
}
```
channelHandler 类结构![图片](https://uploader.shimo.im/f/gPK2V2aI7osRieAJ.png!thumbnail)


执行堆栈：

```
NettyServerCnxnFactory#NettyServerCnxnFactory 	// 初始化netty服务工厂
  > NettyUtils.newNioOrEpollEventLoopGroup 	// 创建IO线程组
  > NettyUtils#newNioOrEpollEventLoopGroup() 	// 创建工作线程组
  >ServerBootstrap#childHandler(io.netty.channel.ChannelHandler) // 添加管道流
>NettyServerCnxnFactory#start 			// 绑定端口，并启动netty服务
```
**创建连接：**

每当有客户端新连接进来，就会进入该方法 创建 NettyServerCnxn对象。并添加至cnxns对例

执行堆栈

```
CnxnChannelHandler#channelActive
 >new NettyServerCnxn 		     // 构建连接器
>NettyServerCnxnFactory#addCnxn     // 添加至连接器，并根据客户端IP进行分组
 >ipMap.get(addr) // 基于IP进行分组
```
**读取消息：**
执行堆栈

```
CnxnChannelHandler#channelRead
>NettyServerCnxn#processMessage //  处理消息 
 >NettyServerCnxn#receiveMessage // 接收消息
  >ZooKeeperServer#processPacket //处理消息包
   >org.apache.zookeeper.server.Request // 封装request 对象
    >org.apache.zookeeper.server.ZooKeeperServer#submitRequest // 提交request  
     >org.apache.zookeeper.server.RequestProcessor#processRequest // 处理请求
```
## 二、快照与事务日志存储结构

---
### 概要:
ZK中所有的数据都是存储在内存中，即zkDataBase中。但同时所有对ZK数据的变更都会记录到事物日志中，并且当写入到一定的次数就会进行一次快照的生成。已保证数据的备份。其后缀就是ZXID（唯一事物ID）。

* 事物日志：每次增删改，的记录日志都会保存在文件当中
* 快照日志：存储了在指定时间节点下的所有的数据
### **存储结构:**
zkDdataBase 是zk数据库基类，所有节点都会保存在该类当中，而对Zk进行任何的数据变更都会基于该类进行。zk数据的存储是通过DataTree 对象进行，其用了一个map 来进行存储。

![图片](https://uploader.shimo.im/f/BUY4rHoJl5MEyCuu.png!thumbnail)

UML 类图：

![图片](https://uploader.shimo.im/f/emgG6FGmkYM7Kb6i.png!thumbnail)

读取快照日志：

```
org.apache.zookeeper.server.SnapshotFormatter
```
读取事物日志：

```
org.apache.zookeeper.server.LogFormatter
```
### 快照相关配置：
| dataLogDir   | 事物日志目录   | 
|:----:|:----|
| zookeeper.preAllocSize | 预先开辟磁盘空间，用于后续写入事务日志，默认64M   | 
| zookeeper.snapCount | 每进行snapCount次事务日志输出后，触发一次快照，默认是100,000   | 
| autopurge.snapRetainCount | 自动清除时 保留的快照数 | 
| autopurge.purgeInterval |  清除时间间隔，小时为单位 -1 表示不自动清除。 | 

### **快照装载流程：**
```
>ZooKeeperServer#loadData // 加载数据
>FileTxnSnapLog#restore // 恢复数据
>FileSnap#deserialize() // 反序列化数据
>FileSnap#findNValidSnapshots // 查找有效的快照
  >Util#sortDataDir // 基于后缀排序文件
    >persistence.Util#isValidSnapshot // 验证是否有效快照文件
```

