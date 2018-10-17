**概要：**
1. Tomcat各核心组件认知
2. Tomcat server.xml 配置详解
3. Tomcat IO模型介绍

## 一、Tomcat各组件认知

---
**知识点：**
1. Tomcat架构说明
2. Tomcat组件及关系详情介绍
3. Tomcat启动参数说明

1. Tomcat架构说明

Tomcat是一个基于JAVA的WEB容器，其实现了JAVA EE中的 Servlet 与 jsp 规范，与Nginx apache 服务器不同在于一般用于动态请求处理。在架构设计上采用面向组件的方式设计。即整体功能是通过组件的方式拼装完成。另外每个组件都可以被替换以保证灵活性。

![图片](http://www.blogjava.net/images/blogjava_net/baoyaer/canImageupload/tomcat-startup.gif?_=2334187)

那么是哪些组件组成了Tomcat呢？
### 2.Tomcat 各组件及关系
* Server 和 Service
* Connector   连接器
  * HTTP 1.1
  * SSL  https
  * AJP（ Apache JServ Protocol） apache 私有协议，用于apache 反向代理Tomcat
* Container 
  * Engine  引擎 catalina
  * Host   虚拟机 基于域名 分发请求
  * Context 隔离各个WEB应用 每个Context的  ClassLoader都是独立
* Component 
  * Manager （管理器）
  * logger （日志管理）
  * loader （载入器）
  * pipeline (管道)
  * valve （管道中的阀）

![图片](https://images-cdn.shimo.im/GMkesXePfg8b93e2/Tomcat_组件架构.png!thumbnail)

### 3.Tomcat启动参数说明
我们平时启动Tomcat过程是怎么样的？ 
1. 复制WAR包至Tomcat webapp 目录。
2. 执行starut.bat 脚本启动。
3. 启动过程中war 包会被自动解压装载。

但是我们在Eclipse 或idea 中启动WEB项目的时候 也是把War包复杂至webapps 目录解压吗？显然不是，其真正做法是在Tomcat程序文件之外创建了一个部署目录，在一般生产环境中也是这么做的 即：Tomcat 程序目录和部署目录分开 。
 我们只需要在启动时指定CATALINA_HOME 与  CATALINA_BASE 参数即可实现。
 
| **启动参数**   | **描述说明**   | 
|:----|:----|
| JAVA_OPTS   | jvm 启动参数 , 设置内存  编码等 -Xms100m -Xmx200m -Dfile.encoding=UTF-8   | 
| JAVA_HOME   | 指定jdk 目录，如果未设置从java 环境变量当中去找。   | 
| CATALINA_HOME   | Tomcat 程序根目录    | 
| CATALINA_BASE   | 应用部署目录，默认为$CATALINA_HOME   | 
| CATALINA_OUT   | 应用日志输出目录：默认$CATALINA_BASE/log   | 
| CATALINA_TMPDIR   | 应用临时目录：默认：$CATALINA_BASE/temp   | 

可以编写一个脚本 来实现自定义配置：
**演示自定义启动Tomcat**
- [ ] 下载并解压Tomcat
- [ ] 创建并拷贝应用目录 
- [ ] 创建Tomcat.sh
    - [ ]  编写Tomcat.sh
    - [ ] chmod +x tomcat.sh 添加执行权限
- [ ] 拷贝conf 、webapps 、logs至应用目录。
- [ ] 执行启动测试。
```
#!/bin/bash 
export JAVA_OPTS="-Xms100m -Xmx200m"
export JAVA_HOME=/root/svr/jdk/
export CATALINA_HOME=/usr/local/apache-tomcat-8.5.34
export CATALINA_BASE="`pwd`"

case $1 in
        start)
        $CATALINA_HOME/bin/catalina.sh start
                echo start success!!
        ;;
        stop)
                $CATALINA_HOME/bin/catalina.sh stop
                echo stop success!!
        ;;
        restart)
        $CATALINA_HOME/bin/catalina.sh stop
                echo stop success!!
                sleep 2
        $CATALINA_HOME/bin/catalina.sh start
        echo start success!!
        ;;
        version)
        $CATALINA_HOME/bin/catalina.sh version
        ;;
        configtest)
        $CATALINA_HOME/bin/catalina.sh configtest
        ;;
        esac
exit 0
```


## 二、Tomcat server.xml 配置详解

---
Server 的基本基本配置：

```
<Server>
    <Listener /><!-- 监听器 -->
    <GlobaNamingResources> <!-- 全局资源 -->
    </GlobaNamingResources
    <Service>          <!-- 服务 用于 绑定 连接器与 Engine -->
        <Connector 8080/> <!-- 连接器-->
        <Connector 8010 /> <!-- 连接器-->
        <Connector 8030/> <!-- 连接器-->
        
        <Engine>      <!-- 执行引擎-->
            <Logger />
            <Realm />
               <host "www.tl.com" appBase="">  <!-- 虚拟主机-->
                   <Logger /> <!-- 日志配置-->
                   <Context "/luban" path=""/> <!-- 上下文配置-->
               </host>
        </Engine>
    </Service>
</Server>
```

**元素说明：**
**server  **
root元素：server 的顶级配置
主要属性:
port：执行关闭命令的端口号
shutdown：关闭命令
- [ ] 演示shutdown的用法
```
#基于telent 执行SHUTDOWN 命令即可关闭
telent 127.0.0.1 8005
SHUTDOWN
```

**service**
服务：将多个connector 与一个Engine组合成一个服务，可以配置多个服务。

**Connector**
连接器：用于接收 指定协议下的连接 并指定给唯一的Engine 进行处理。
主要属性：
* protocol 监听的协议，默认是http/1.1
* port 指定服务器端要创建的端口号
* minThread	服务器启动时创建的处理请求的线程数
* maxThread	最大可以创建的处理请求的线程数
* enableLookups	如果为true，则可以通过调用request.getRemoteHost()进行DNS查询来得到远程客户端的实际主机名，若为false则不进行DNS查询，而是返回其ip地址
* redirectPort	指定服务器正在处理http请求时收到了一个SSL传输请求后重定向的端口号
* acceptCount	指定当所有可以使用的处理请求的线程数都被使用时，可以放到处理队列中的请求数，超过这个数的请求将不予处理
* connectionTimeout	指定超时的时间数(以毫秒为单位)
* SSLEnabled 是否开启 sll 验证，在Https 访问时需要开启。
- [ ] *演示配置多个Connector*
```
 <Connector port="8860" protocol="org.apache.coyote.http11.Http11NioProtocol"
                connectionTimeout="20000"
                redirectPort="8862"
                URIEncoding="UTF-8"
                useBodyEncodingForURI="true"
                compression="on" compressionMinSize="2048"
compressableMimeType="text/html,text/xml,text/plain,text/javascript,text/css,application/x-json,application/json,application/x-javascript"
                maxThreads="1024" minSpareThreads="200"
                acceptCount="800"
                enableLookups="false"
        />
```
**Engine**
引擎：用于处理连接的执行器，默认的引擎是catalina。一个service 中只能配置一个Engine。
主要属性：name 引擎名称 defaultHost 默认host

**Host**
虚拟机：基于域名匹配至指定虚拟机。类似于nginx 当中的server,默认的虚拟机是localhost.
主要属性：
- [ ] *演示配置多个Host*
```
<Host name="www.luban.com"  appBase="/usr/www/luban"
            unpackWARs="true" autoDeploy="true">
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"               prefix="www.luban.com.access_log" suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />
</Host>
```

**Context**
应用上下文：一个host 下可以配置多个Context ，每个Context 都有其独立的classPath。相互隔离，以免造成ClassPath 冲突。
主要属性：
- [ ] *演示配置多个Context*
```
<Context docBase="hello" path="/h" reloadable="true"/>
```

**Valve**
阀门：可以理解成request 的过滤器，具体配置要基于具体的Valve 接口的子类。以下即为一个访问日志的Valve.
```
 <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="www.luban.com.access_log" suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />
```

## 三、Tomcat IO模型介绍

---
知识点：
1. Tomcat支持的IO模型说明
2. BIO 与NIO的区别
3. IO模型源码解读
### **1、Tomcat支持的IO模型说明**
|    | 描述   | 
|:----|:----|
| BIO   | 阻塞式IO，即Tomcat使用传统的java.io进行操作。该模式下每个请求都会创建一个线程，对性能开销大，不适合高并发场景。优点是稳定，适合连接数目小且固定架构。   | 
| NIO   | 非阻塞式IO，jdk1.4 之后实现的新IO。该模式基于多路复用选择器监测连接状态在通知线程处理，从而达到非阻塞的目的。比传统BIO能更好的支持并发性能。Tomcat 8.0之后默认采用该模式   | 
| APR   | 全称是 Apache Portable Runtime/Apache可移植运行库)，是Apache HTTP服务器的支持库。可以简单地理解为，Tomcat将以JNI的形式调用Apache HTTP服务器的核心动态链接库来处理文件读取或网络传输操作。使用需要编译安装APR 库   | 
| AIO   | 异步非阻塞式IO，jdk1.7后之支持 。与nio不同在于不需要多路复用选择器，而是请求处理线程执行完程进行回调调知，已继续执行后续操作。Tomcat 8之后支持。   | 
|    |    | 

**使用指定IO模型的配置方式:**
配置 server.xml 文件当中的 <Connector  protocol="HTTP/1.1">    修改即可。
默认配置 8.0  protocol=“HTTP/1.1” 8.0 之前是 BIO 8.0 之后是NIO
**BIO**
protocol=“org.apache.coyote.http11.Http11Protocol“
**NIO**
protocol=”org.apache.coyote.http11.Http11NioProtocol“
**AIO**
protocol=”org.apache.coyote.http11.Http11Nio2Protocol“
**APR**
protocol=”org.apache.coyote.http11.Http11AprProtocol“

### 2、BIO 与NIO有什么区别
**分别演示在高并发场景下BIO与NIO的线程数的变化？**
**演示数据：**
|    | 每秒提交数   | BIO执行线程   | NIO执行线程   |    | 
|:----|:----|:----|:----|:----|
| 预测   | 200   | 200   | 50   |    | 
| 实验环境   | 200   | 48   | 37   |    | 
| 生产环境   | 200   | 419   | 23   |    | 

**结论：**

**BIO 线程模型讲解**
![图片](https://images-cdn.shimo.im/mNNI3LANwOo9GFLB/image.png!thumbnail)

**NIO 线程模型讲解**
![图片](https://images-cdn.shimo.im/AMRoheY0pHEaIfJK/image.png!thumbnail)

**BIO 源码解读**
1. Http11Protocol  Http BIO协议解析器
  1. JIoEndpoint
    1. Acceptor implements Runnable
    2. SocketProcessor implements Runnable
2. Http11NioProtocol Http Nio协议解析器
  1. NioEndpoint
    1. Acceptor  implements Runnable
    2. Poller implements Runnable 
    3. SocketProcessor implements Runnable 





