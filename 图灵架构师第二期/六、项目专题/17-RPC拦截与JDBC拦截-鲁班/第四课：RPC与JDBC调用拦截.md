**课程概要：**
1. dubbo 发送请求拦截
2. dubbo接收请求拦截
3. jdbc调用拦截


## 一、dubbo 发送请求拦截

---
**知识点：**
1. 埋点采集目标
2. dubbo执行过程分析
3. 实现dubbo发送请求埋点


1. 埋点采集目标

捕捉消费者调用信息（远程接口、URL、参数、用时、返回结果、异常）
调用信息模型表结构：
| **名称**   | **类型**   | **描述**   | 
|:----|:----|:----|
| servicePath   | string   | 服务路径   | 
| serviceName   | string   | 服务   | 
| inParam   | json   | 返回结果   | 
| outParam   | json   | 返回结果   | 
| ErrorMessage   | string   | 异常信息   | 
| ErrorStack   | text   | 异常堆栈   | 
| ResultState   | string   | 执行状态   | 
| beginTime   | date   | 开始时间   | 
| endTime   | date   | 结束时间   | 
| addressIp   | string   | 远程IP   | 
| fromIp   | string   | 调用者IP   | 


**可用性目标：**
1、兼容更多的Dubbo版本
2、应该勿略RPC中间操作（容错、负载、Mock、Filter...）
### 2、dubbo执行过程分析
* Dubbo 基本架构：

![图片](https://images-cdn.shimo.im/IHfKKmx5RyI5Qfkr/dubbo_architecture.jpg!thumbnail)
| **节点**   | **角色说明**   | 
|:----|:----|
| Provider   | 暴露服务的服务提供方   | 
| Consumer   | 调用远程服务的服务消费方   | 
| Registry   | 服务注册与发现的注册中心   | 
| Monitor   | 统计服务的调用次数和调用时间的监控中心   | 
| Container   | 服务运行容器   | 

* Dubbo调用过程 ：

![图片](https://images-cdn.shimo.im/nygYt7P9od0M3bLI/image.png!thumbnail)
* 消费者调用线程源码分析：![图片](https://images-cdn.shimo.im/DAQqyChsDB8A4uyR/dubbo_消息费调用图.png!thumbnail)

在消费端埋点 在尽可能的靠近原调用方法，同时又要满足信息的采集需求，所以经综合考虑选择MockClusterInvoker 是比较合适的。
### 3.实现dubbo发送请求埋点
基于multicast协议搭建测试服务
* 提供者配置：
```
<dubbo:application name="demo-provider"/>
<dubbo:registry address="multicast://224.5.6.7:1234?unicast=false"/>
<dubbo:protocol name="dubbo" port="-1"/>
<dubbo:service interface="com.test.service.UserService" ref="userServiceImpl"/>
<bean id="userServiceImpl" class="com.test.service.UserServiceImpl"/>
```
* 消费者配置：
```
<dubbo:application name="demo-consumer"/>
    <dubbo:registry address="multicast://224.5.6.7:1234?unicast=false"
                    register="true"/>
    <dubbo:reference id="userService" timeout="2000"
                     interface="com.test.service.UserService" check="false"/>
```

* 编写DubboConsumerAgent 代码：
```
package com.tuling.agent;

import com.alibaba.dubbo.rpc.Invocation;
import com.alibaba.dubbo.rpc.Invoker;
import com.alibaba.dubbo.rpc.RpcInvocation;
import javassist.*;

import java.io.Serializable;
import java.lang.instrument.ClassFileTransformer;
import java.lang.instrument.IllegalClassFormatException;
import java.lang.instrument.Instrumentation;
import java.security.ProtectionDomain;
import java.util.Arrays;
import java.util.UUID;

/**
 * @author Tommy
 * Created by Tommy on 2019/3/24
 **/
public class DubboConsumerAgent {
    private static String target = "com.alibaba.dubbo.rpc.cluster.support.wrapper.MockClusterInvoker";

    public static void premain(String args, Instrumentation instrumentation) {
        System.out.println("dubbo 拦截");
        instrumentation.addTransformer(new ClassFileTransformer() {
            @Override
            public byte[] transform(ClassLoader loader, String className,
                                    Class<?> classBeingRedefined,
                                    ProtectionDomain protectionDomain,
                                    byte[] classfileBuffer) throws IllegalClassFormatException {
                if (!target.replaceAll("\\.", "/").equals(className)) {
                    return null;
                }
                try {
                    return buildBytes(loader, target);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                return null;
            }
        });
    }

    private static byte[] buildBytes(ClassLoader loader, String target) throws Exception {
        ClassPool pool = new ClassPool();
        pool.insertClassPath(new LoaderClassPath(loader));
        CtClass ctClass = pool.get(target);
        CtMethod method = ctClass.getDeclaredMethod("invoke");
        CtMethod copyMethod = CtNewMethod.copy(method, ctClass, new ClassMap());
        method.setName(method.getName() + "$agent");
        copyMethod.setBody("{\n" +
                "               Object trace= com.tuling.agent.DubboConsumerAgent.begin($args,$0);\n" +
                "                try {\n" +
                "                     return " + copyMethod.getName() + "$agent($$);\n" +
                "                } finally {\n" +
                "                   com.tuling.agent.DubboConsumerAgent.end(trace);\n" +
                "                }\n" +
                "            }");

        ctClass.addMethod(copyMethod);
        return ctClass.toBytecode();
    }

    public static Object begin(Object[] args, Object invoker) {
        RpcInvocation invocation = (RpcInvocation) args[0];
        // 用于获取url 信息
        Invoker dubboInvoker = (Invoker) invoker;
        DubboInfo info = new DubboInfo();
        info.url = dubboInvoker.getUrl().toFullString();
        info.interfaceName = dubboInvoker.getInterface().getName();
        info.methodName = invocation.getMethodName();
        info.begin = System.currentTimeMillis();
        info.params = invocation.getArguments();


        TraceSession session = TraceSession.getCurrentSession();
        info.traceId = session.getTraceId();
        info.eventId = session.getParentId() + "." + session.getNextEventId();
        invocation.setAttachment("_traceId", info.traceId);
        invocation.setAttachment("_parentId", info.eventId);
        return info;
    }

    public static void end(Object param) {
        System.out.println(param);
    }

    public static class DubboInfo implements Serializable {
        private String traceId;
        private String eventId;
        private String interfaceName;
        private String methodName;
        private Long begin;
        private String url;
        private Object params[];

        public String getTraceId() {
            return traceId;
        }

        public void setTraceId(String traceId) {
            this.traceId = traceId;
        }

        public String getEventId() {
            return eventId;
        }

        public void setEventId(String eventId) {
            this.eventId = eventId;
        }

        public Long getBegin() {
            return begin;
        }

        public void setBegin(Long begin) {
            this.begin = begin;
        }

        public String getUrl() {
            return url;
        }

        public void setUrl(String url) {
            this.url = url;
        }

        public Object[] getParams() {
            return params;
        }

        public void setParams(Object[] params) {
            this.params = params;
        }

        @Override
        public String toString() {
            return "DubboInfo{" +
                    "traceId='" + traceId + '\'' +
                    ", eventId='" + eventId + '\'' +
                    ", interfaceName='" + interfaceName + '\'' +
                    ", methodName='" + methodName + '\'' +
                    ", begin=" + begin +
                    ", url='" + url + '\'' +
                    ", params=" + Arrays.toString(params) +
                    '}';
        }
    }
}
```

## 二、dubbo接收请求拦截

---
**知识点：**
1. 埋点目的
2. 埋点位置
3. 具体实现

### **1.埋点目的**

在第一课我们讲过分布式的调用链其中一个特性是追踪整个链路，包括跨节点的远程调用。为了实现这一点，就需要将TraceId 与EventID 传递基于其特定的RPC调用传递到一下个节点。
![图片](https://uploader.shimo.im/f/Yy9TVTaBT9oMkIAF.png!thumbnail)


![图片](https://uploader.shimo.im/f/n7CgHmwR0T4r9XIV.png!thumbnail)
所以Dubbo的提供端的埋点主要作用是 接收远程传递过来的TraceId 并在当前节点开启追踪会话。

### 2.埋点位置分析
* 提供者处理线程分析

![图片](https://images-cdn.shimo.im/fzJcXFl1Es49joQC/dubbo提供者处理过程.png!thumbnail)

经分析埋点位置选在离实际调用方法较远的ClassLoaderFilter过滤器理由是捕捉的信息更全面。

### 3.具体编码实现
```
package com.tuling.agent;

import com.alibaba.dubbo.rpc.Invoker;
import com.alibaba.dubbo.rpc.RpcInvocation;
import javassist.*;

import java.lang.instrument.ClassFileTransformer;
import java.lang.instrument.IllegalClassFormatException;
import java.lang.instrument.Instrumentation;
import java.security.ProtectionDomain;

/**
 * @author Tommy
 * Created by Tommy on 2019/3/24
 **/
public class DubboProvideAgent {
    public static void premain(String args, Instrumentation instrumentation) {
        System.out.println("dubbo 拦截");
        instrumentation.addTransformer(new ClassFileTransformer() {
            @Override
            public byte[] transform(ClassLoader loader, String className,
                                    Class<?> classBeingRedefined,
                                    ProtectionDomain protectionDomain,
                                    byte[] classfileBuffer) throws IllegalClassFormatException {
                if (!"com/alibaba/dubbo/rpc/filter/ClassLoaderFilter".equals(className)) {
                    return null;
                }
                try {
                    return buildBytes(loader, className.replaceAll("/", "."));
                } catch (Exception e) {
                    e.printStackTrace();
                }
                return null;
            }
        });
    }

    private static byte[] buildBytes(ClassLoader loader, String target) throws Exception {
        ClassPool pool = new ClassPool();
        pool.insertClassPath(new LoaderClassPath(loader));
        CtClass ctClass = pool.get(target);
        CtMethod method = ctClass.getDeclaredMethod("invoke");
        CtMethod copyMethod = CtNewMethod.copy(method, ctClass, new ClassMap());
        method.setName(method.getName() + "$agent");
        copyMethod.setBody("{\n" +
                "               Object trace= com.tuling.agent.DubboProvideAgent.begin($args);\n" +
                "                try {\n" +
                "                     return " + copyMethod.getName() + "$agent($$);\n" +
                "                } finally {\n" +
                "                   com.tuling.agent.DubboProvideAgent.end(trace);\n" +
                "                }\n" +
                "            }");

        ctClass.addMethod(copyMethod);
        return ctClass.toBytecode();
    }

    public static Object begin(Object[] args) {
        Invoker i = (Invoker) args[0];
        RpcInvocation rpcInvocation = (RpcInvocation) args[1];
        String traceId = rpcInvocation.getAttachment("_traceId");
        String parentId = rpcInvocation.getAttachment("_parentId");
        System.out.println("服务接收 traceId=" + traceId);
        TraceSession session = new TraceSession(traceId, parentId);
        return new Object();
    }

    public static void end(Object arg) {
        // 关闭会话
        TraceSession.getCurrentSession().close();
    }
}
```
## 三、jdbc调用拦截

---
**知识点：**
1. JDBC插桩目的
2. JDBC插桩位置
3. JDBC插桩机制

1. **JDBC插桩目的**
  1. SQL语句、SQL参数、用了多长时间、SQL类型、结果集大小、返回字段、规范、Join次数
  2. 拦截监听SQL语句
  3. 找出慢查询语句
  4. ...


可用性需求：
  跟项目无关
  跟框架无关（myBatis,Hibernate\Spring template \JDBC）
  跟数据库无关 (oracle,mysql,SqlServer)


* 模型结构：
| 字段   | 类型   | 描述   | 
|:----|:----|:----|
| sql   | text   | sql语句   | 
| params   | json   | 参数   | 
| resultSize   | int   | 结果大小   | 
| url   | varchar   | 数据库连接路径   | 
| userName   | varchar   | 数据库用户名   | 
| error   | text   | 异常堆栈   | 
| useTime   | int   | 用时   | 

### **2.JDBC插桩位置**
* JDBC 应用场景分析

![图片](https://images-cdn.shimo.im/0fEHaRPxFXoHlSkF/image.png!thumbnail)

从上图可以看出任任何一层都可以做为插桩的切入点，但是选用User 层、框架层、连接池&数据源层、驱动层其实现是多样的，无法做到普适性。所以在此选用JDBC 作为插桩切入 点。问题是JDBC仅是一由堆接口组成规范，如何插桩呢？
### **3.JDBC插桩机制**
* JDBC 时序图分析：

![图片](https://images-cdn.shimo.im/vBJt5npvvjEuHItz/image.png!thumbnail)

从上图可以分析出JDBC执行过程是：
1. 从驱动获取连接(Connection) 
2. 基于连接构建预处理对象（prepareStatement）
3. 执行SQL
4. 读取结果集（ResultSet）
5. 关闭释放连接。

其中涉及对象构建逻辑如下：
Driver==》Connection==》prepareStatement==》ResultSet
- [ ] 生成过程演示

如果在此之上加一层**动态代理**即可监控这些对象所有的执行过程从而得到所需监控数据:
Driver==》Proxy(Connection)==》Proxy(prepareStatement)==》Proxy(ResultSet)
| **对象**   | **监控点**   | 
|:----|:----|
| Connection   | 连接URL、数据库名、用户名   | 
| prepareStatement   | SQL语句、SQL参数   | 
| ResultSet   | 结果集   | 


**4.JDBC埋点实践：**
```
package com.tuling.agent;

import javassist.*;

import java.io.Serializable;
import java.lang.instrument.ClassFileTransformer;
import java.lang.instrument.IllegalClassFormatException;
import java.lang.instrument.Instrumentation;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.security.ProtectionDomain;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/**
 * @author Tommy
 * Created by Tommy on 2019/3/24
 **/
public class JdbcAgent {


    public static void premain(String args, Instrumentation instrumentation) {
        System.out.println("mysql 拦截 ");
        instrumentation.addTransformer(new ClassFileTransformer() {
            @Override
            public byte[] transform(ClassLoader loader, String className, Class<?> classBeingRedefined, ProtectionDomain protectionDomain, byte[] classfileBuffer) throws IllegalClassFormatException {
                if (!"com/mysql/jdbc/NonRegisteringDriver".equals(className)) {
                    return null;
                }
                try {
                    return build(loader, className.replaceAll("/", "."));
                } catch (Exception e) {
                    e.printStackTrace();
                }
                return null;
            }
        });
    }

    private static byte[] build(ClassLoader loader, String name) throws Exception {
        ClassPool pool = new ClassPool();
        pool.insertClassPath(new LoaderClassPath(loader));
        CtClass ctClass = pool.get(name);
        CtMethod method = ctClass.getDeclaredMethod("connect");
        CtMethod copyMethod = CtNewMethod.copy(method, ctClass, new ClassMap());
        method.setName(method.getName() + "$agent");
        copyMethod.setBody("{\n" +
                "            return com.tuling.agent.JdbcAgent.proxyConnection(connect$agent($$));\n" +
                "        }");
        ctClass.addMethod(copyMethod);
        return ctClass.toBytecode();
    }

    public static Connection proxyConnection(final Connection connection) {
        Object c = Proxy.newProxyInstance(connection.getClass().getClassLoader()
                , new Class[]{Connection.class}, new ConnectionHandler(connection));
        return (Connection) c;
    }

    public static PreparedStatement proxyPreparedStatement(final PreparedStatement statement, Object jdbcStat) {
        Object c = Proxy.newProxyInstance(statement.getClass().getClassLoader()
                , new Class[]{PreparedStatement.class}, new PreparedStatementHandler(statement, jdbcStat));
        return (PreparedStatement) c;
    }

    public static Object begin(Connection connection, String sql) {
        JdbcStatistics jdbcStat = new JdbcStatistics();
        try {
            jdbcStat.jdbcUrl = connection.getMetaData().getURL();
        } catch (SQLException e) {
            e.printStackTrace();
        }
        jdbcStat.begin = System.currentTimeMillis();
        TraceSession session = TraceSession.getCurrentSession();
        if (session != null) {
            jdbcStat.traceId = session.getTraceId();
            jdbcStat.eventId = session.getParentId() + "." + session.getNextEventId();
        }
        jdbcStat.sql = sql;
        return jdbcStat;
    }

    private static void end(Object jdbcStat) {
        JdbcStatistics stat = (JdbcStatistics) jdbcStat;
        stat.useTime = System.currentTimeMillis() - stat.getBegin();
        System.out.println(jdbcStat);
    }

    /**
     * connection 代理处理
     */
    public static class ConnectionHandler implements InvocationHandler {
        private final Connection connection;

        private ConnectionHandler(Connection connection) {
            this.connection = connection;
        }

        public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            boolean isTargetMethod = "prepareStatement".equalsIgnoreCase(method.getName());
            Object result = null;
            Object jdbcStat = null;
            try {
                if (isTargetMethod) { // 获取PreparedStatement 开始统计
                    jdbcStat = begin(connection, (String) args[0]);
                }
                result = method.invoke(connection, args);
                // 代理 PreparedStatement
                if (isTargetMethod && result instanceof PreparedStatement) {
                    PreparedStatement ps = (PreparedStatement) result;
                    result = proxyPreparedStatement(ps, jdbcStat);
                }
            } catch (Throwable e) {
                throw e;
            } finally {

            }
            return result;
        }
    }


    /**
     * PreparedStatement 代理处理
     */
    public static class PreparedStatementHandler implements InvocationHandler {
        private final PreparedStatement statement;
        private final Object jdbcStat;

        public PreparedStatementHandler(PreparedStatement statement, Object jdbcStat) {
            this.statement = statement;
            this.jdbcStat = jdbcStat;
        }

        public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            boolean isTargetMethod = false;
            for (String agentm : new String[]{"execute", "executeUpdate", "executeQuery"}) {
                if (agentm.equals(method.getName())) {
                    isTargetMethod = true;
                    break;
                }
            }
            Object result = null;
            try {
                result = method.invoke(statement, args);
            } catch (Throwable e) {
                throw e;
            } finally {
                if ("close".equals(method.getName())) {
                    end(jdbcStat);
                }
            }
            return result;
        }


    }

    // 实现 jdbc 数据采集器
    public static class JdbcStatistics implements Serializable {
        private String traceId;
        private String eventId;
        private Long useTime;
        public Long begin;// 时间戳
        // jdbc url
        public String jdbcUrl;
        // sql 语句
        public String sql;
        // 数据库名称
        public String databaseName;

        public String getTraceId() {
            return traceId;
        }

        public void setTraceId(String traceId) {
            this.traceId = traceId;
        }

        public String getEventId() {
            return eventId;
        }

        public void setEventId(String eventId) {
            this.eventId = eventId;
        }

        public Long getBegin() {
            return begin;
        }

        public void setBegin(Long begin) {
            this.begin = begin;
        }

        public String getJdbcUrl() {
            return jdbcUrl;
        }

        public void setJdbcUrl(String jdbcUrl) {
            this.jdbcUrl = jdbcUrl;
        }

        public String getSql() {
            return sql;
        }

        public void setSql(String sql) {
            this.sql = sql;
        }

        public String getDatabaseName() {
            return databaseName;
        }

        public void setDatabaseName(String databaseName) {
            this.databaseName = databaseName;
        }

        public Long getUseTime() {
            return useTime;
        }

        public void setUseTime(Long useTime) {
            this.useTime = useTime;
        }

        @Override
        public String toString() {
            return "JdbcStatistics{" +
                    "traceId='" + traceId + '\'' +
                    ", eventId='" + eventId + '\'' +
                    ", useTime='" + useTime + '\'' +
                    ", begin=" + begin +
                    ", jdbcUrl='" + jdbcUrl + '\'' +
                    ", sql='" + sql + '\'' +
                    ", databaseName='" + databaseName + '\'' +
                    '}';
        }
    }
}
```
## 

