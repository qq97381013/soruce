**课程概要：**
1. Tomcat 支持四种线程模型介绍
2. Tomcat BIO、NIO实现过程源码解析
3. Tomcat connector 并发参数解读
4. Tomcat 类加载机制源码解析
## **一、Tomcat 支持四种线程模型介绍**
**什么是IO?**
IO是指为数据传输所提供的输入输出流，其输入输出对象可以是：文件、网络服务、内存等。

![图片](https://images-cdn.shimo.im/s7TyCRgxcXY2qIfy/image.png!thumbnail)
**什么是IO模型？**
提问：
假设应用在从硬盘中读取一个大文件过程中，此时CPU会与硬盘一样出于高负荷状态么？
演示：
- [ ] 演示观察大文件的读写过程当中CPU 有没有发生大波动。

演示结果：CPU 没有太高的增涨
通常情况下IO操作是比较耗时的，所以为了高效的使用硬件，应用程序可以用一个专门线程进行IO操作，而另外一个线程则利用CPU的空闲去做其它计算。这种为提高应用执行效率而采用的IO操作方法即为IO模型。

**各IO 简单说明:**
| IO模型   | 描述   | 
|:----|:----|
| BIO   |  同步阻塞式IO，即Tomcat使用传统的java.io进行操作。该模式下每个请求都会创建一个线程，对性能开销大，不适合高并发场景。优点是稳定，适合连接数目小且固定架构。   | 
| NIO   | 同步非阻塞式IO，jdk1.4 之后实现的新IO。该模式基于多路复用选择器监测连接状态在同步通知线程处理，从而达到非阻塞的目的。比传统BIO能更好的支持并发性能。Tomcat 8.0之后默认采用该模式   | 
| APR   |  全称是 Apache Portable Runtime/Apache可移植运行库)，是Apache HTTP服务器的支持库。可以简单地理解为，Tomcat将以JNI的形式调用Apache HTTP服务器的核心动态链接库来处理文件读取或网络传输操作。使用需要编译安装APR 库   | 
| AIO  (asynchronous  I/O)   |  异步非阻塞式IO，jdk1.7后之支持 。与nio不同在于不需要多路复用选择器，而是请求处理线程执行完程进行回调调知，已继续执行后续操作。Tomcat 8之后支持。   | 

**使用指定IO模型的配置方式:**
配置 server.xml 文件当中的 <Connector  protocol="HTTP/1.1">   修改即可。
默认配置 8.0  protocol=“HTTP/1.1” 8.0 之前是 BIO 8.0 之后是NIO
**BIO**
protocol=“org.apache.coyote.http11.Http11Protocol“ 
**NIO**
protocol=”org.apache.coyote.http11.Http11NioProtocol“
**AIO**
protocol=”org.apache.coyote.http11.Http11Nio2Protocol“
**APR**
protocol=”org.apache.coyote.http11.Http11AprProtocol“


## **二、Tomcat BIO、NIO实现过程源码解析**

---
**提问：**
BIO 与NIO有什么区别？

**分别演示在高并发场景下BIO与NIO的线程数的变化？**
**演示数据：**
|    | **每秒提交数**   | **BIO执行线程**   | **NIO执行线程**   | 
|:----|:----|:----|:----|
| 预测   | 200   | 200线程   | 20线程   | 
| 实验实际   | 200   | 55 wait个线程   | 23个线程   | 
| 模拟生产环境   | 200   | 229个run线程   | 20个wait 线程   | 

1、网络
2、程序执行业务用时

**结论：**

**BIO 线程模型讲解**

![图片](https://images-cdn.shimo.im/mNNI3LANwOo9GFLB/image.png!thumbnail)

**NIO 线程模型讲解**
![图片](https://images-cdn.shimo.im/AMRoheY0pHEaIfJK/image.png!thumbnail)

**BIO 源码解读**
**线程组：**
Accept 线程组  acceptorThreadCount=
exec 线程组    maxThread

JIoEndpoint
	Acceptor extends Runnable
	SocketProcessor extends Runnable

**BIO**
 线程数量 会受到 客户端阻塞、网络延迟、业务处理慢===>线程数会更多
**NIO**
 线程数量 会受到业务处理慢===>线程数会更多
## **三、Tomcat connector 并发参数解读**

---
| 名称   | 描述   | 
|:----|:----|
| acceptCount   | 等待最大队列   | 
| address   | 绑定客户端特定地址，127.0.0.1   | 
| bufferSize   | 每个请求的缓冲区大小。bufferSize * maxThreads   | 
| compression   | 是否启用文档压缩   | 
| compressableMimeTypes   | text/html,text/xml,text/plain   | 
| connectionTimeout   | 客户发起链接 到 服务端接收为止，中间最大的等待时间   | 
| connectionUploadTimeout   | upload 情况下连接超时时间   | 
| disableUploadTimeout   | true 则使用connectionTimeout   | 
| enableLookups   | 禁用DNS查询 true   | 
| keepAliveTimeout   | 当长链接闲置 指定时间主动关闭 链接 ，前提是客户端请求头 带上这个 head"connection" " keep-alive"   | 
| maxKeepAliveRequests   | 最大的 长连接数   | 
| maxHttpHeaderSize   |    | 
| maxSpareThreads   | BIO 模式下 最多线闲置线程数   | 
| maxThreads（执行线程）   | 最大执行线程数   | 
| minSpareThreads(初始线业务线程 10)   | BIO 模式下 最小线闲置线程数   | 


四、Tomcat 类加载机制源码解析

---
### 类加载的本质
是用来加载 Class 的。它负责将 Class 的字节码形式转换成内存形式的 Class 对象。字节码可以来自于磁盘文件 *.class，也可以是 jar 包里的 *.class，也可以来自远程服务器提供的字节流，字节码的本质就是一个字节数组 []byte，它有特定的复杂的内部格式。
JVM 运行实例中会存在多个 ClassLoader，不同的 ClassLoader 会从不同的地方加载字节码文件。它可以从不同的文件目录加载，也可以从不同的 jar 文件中加载，也可以从网络上不同的静态文件服务器来下载字节码再加载。
jvm里ClassLoader的层次结构
![图片](https://uploader.shimo.im/f/os80XKQ1eMAvwFkT.png!thumbnail)
类加载器层次结构.png
**BootstrapClassLoader（启动类加载器）**
负责加载 JVM 运行时核心类,加载System.getProperty("sun.boot.class.path")所指定的路径或jar
**ExtensionClassLoader**
负责加载 JVM 扩展类，比如 swing 系列、内置的 js 引擎、xml 解析器 等等，这些库名通常以 javax 开头，它们的 jar 包位于 JAVAHOME/lib/rt.jar文件中.
加载System.getProperty("java.ext.dirs")所指定的路径或jar。在使用Java运行程序时，也可以指定其搜索路径，例如：java -Djava.ext.dirs=d:\projects\testproj\classes HelloWorld。
**AppClassLoader**
才是直接面向我们用户的加载器，它会加载 Classpath 环境变量里定义的路径中的 jar 包和目录。我们自己编写的代码以及使用的第三方 jar 包通常都是由它来加载的。
加载System.getProperty("java.class.path")所指定的路径或jar。在使用Java运行程序时，也可以加上-cp来覆盖原有的Classpath设置，例如： java -cp ./lavasoft/classes HelloWorld
### **Tomcat的 类加载顺序**
![图片](https://uploader.shimo.im/f/Ykge21GXZq87DTOC.png!thumbnail)
    在Tomcat中，默认的行为是先尝试在Bootstrap和Extension中进行类型加载，如果加载不到则在WebappClassLoader中进行加载，如果还是找不到则在Common中进行查找。。

###  NoClassDefFoundError
NoClassDefFoundError是在开发JavaEE程序中常见的一种问题。该问题会随着你所使用的JavaEE中间件环境的复杂度以及应用本身的体量变得更加复杂，尤其是现在的JavaEE服务器具有大量的类加载器。
在JavaDoc中对NoClassDefFoundError的产生是由于JVM或者类加载器实例尝试加载类型的定义，但是该定义却没有找到，影响了执行路径。换句话说，在编译时这个类是能够被找到的，但是在执行时却没有找到。
这一刻IDE是没有出错提醒的，但是在运行时却出现了错误。
### NoSuchMethodError
在另一个场景中，我们可能遇到了另一个错误，也就是NoSuchMethodError。
NoSuchMethodError代表这个类型确实存在，但是一个不正确的版本被加载了。
### ClassCastException
ClassCastException，在一个类加载器的情况下，一般出现这种错误都会是在转型操作时，比如：A a = (A) method();，很容易判断出来method()方法返回的类型不是类型A，但是在 JavaEE 多个类加载器的环境下就会出现一些难以定位的情况。

