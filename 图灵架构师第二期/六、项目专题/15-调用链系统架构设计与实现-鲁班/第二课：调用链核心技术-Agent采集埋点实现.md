**概要：**
1. javaagent实现机制与使用
2. javassist实现机制与使用
3. 实现server埋点拦截



## 一、javaagent实现机制与使用

---
**概要：**
1. 关于埋点的知识回顾
2. javaagent 介绍
3. javaagent 使用演示
### 1、关于埋点的知识回顾
基于上节课所讲，调用链的核心就采集系统中各节点发生的事件，并进行串联展示。
![图片](https://images-cdn.shimo.im/6CqOOHDgovIvuhap/image.png!thumbnail)

这里的采集过程即为埋点，埋点的方式有：
1.  硬编码埋点捕捉
2. AOP埋点捕捉
3. 公共组件埋点捕捉
4. 字节码插桩捕捉

前面三种方试虽然简单但对系统造成了侵入，系统规模过大时并不可取，所以我们重点研究第四种方式。
**字节码插桩**
我们知道JVM是不能直接执行.java 代码 也不能直接执行.class文件，它只能执行.class 文件中存储的指令码。这就是为什么class 需要通过classLoader 装载以后才能运行。基于此机制可否在ClassLoader装载之前拦截修改class当中的内容(jvm 指令码）从而让程序中包含我们的埋点逻辑呢?答案是肯定的，但需要用到两个技术 javaagent与javassist 。前者用于拦截ClassLoad装载，后者用于操作修改class 文件。，
### 2、javaagent介绍
**Java Agent**
	javaagent 是java1.5之后引入的特性，其主要作用是在class 被加载之前对其拦截，已插入我们的监听字节码
![图片](https://images-cdn.shimo.im/3xDODC6QBHkUWe3W/image.png!thumbnail)

**javaagent jar包**
javaagent 最后展现形式是一个Jar包，有以下特性
1. 必须 META-INF/MANIFEST.MF中指定Premain-Class 设定启agent启动类。
2. 在启类需写明启动方法 public static void main(String arg,) 
3. 不可直接运行，只能通过 jvm 参数-javaagent:xxx.jar 附着于其它jvm 进程运行。
### 2、javaagent使用演示
1、编写 agent 方法:
```
public class TulingAgent {
    public static void premain(String args, Instrumentation instrumentation) {
        System.out.println("hello javaagent premain:" + args);
    }
}
```
2、添加premain-class 参数
```
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-jar-plugin</artifactId>
    <version>2.2</version>
    <configuration>
        <archive>
            <manifestEntries>
                <Project-name>${project.name}</Project-name>
                <Project-version>${project.version}</Project-version>
                <Premain-Class>com.tuling.agent.TulingAgent</Premain-Class>
                <Can-Redefine-Classes>false</Can-Redefine-Classes>
            </manifestEntries>
        </archive>
        <skip>true</skip>
    </configuration>
</plugin>
```

3、构建打包
4、在任一JAVA应用中 添加jvm 参数并启动 -javaagent:xxx.jar

**javaagent ****META-INF/MANIFEST.MF**** 参数说明：**
| 参数   | 默认   | 描述   | 
|:----|:----|:----|
| Premain-Class   |    | 【必填】 agent 启动class   | 
| Can-Redefine-Classes | false   | 是否允许重新定义class   | 
| Can-Retransform-Classes | false   | 是否允许重置Class，重置后相当于class 从classLoade中清除，下次有需要的时候会重新装载，也会重新走Transformer 流程。   | 
| Boot-Class-Path   |    | agent 所依赖的jar 路径 。多个用空格分割   | 


## 二、javassist实现机制与使用

---
1. javassist 介绍
2. javassist 使用演示
3. javassist 特殊语法使用


1. javassist 介绍

	Javassist是一个开源的分析、编辑和创建Java字节码的类库。其主要的优点，在于简单，而且快速。直接使用java编码的形式，而不需要了解虚拟机指令，就能动态改变类的结构，或者动态生成
**注**：也可以使用ASM实现，但需要会操作字节码指令，学习使用成本高

### 2.javassist 使用演示
- [ ] 演示插入打印当前时间代码
- [ ] 演示插入计算方法执行时间代码
### 3.javassist 特殊语法 
| $0, $1, $2, ...       | 方法参数 $0 表示this $1 第一个参数 $2 第二个参数，以此类推....  注：静态方法没有this 所以$0  不存在   | 
|:----|:----|
| $args   | 将参数，以Object 数组的形式进行封装 相当于new Object[]{$1,$2,...}   | 
| $cflow(...)   | 方法在递归调用时 可读取其递归的层次   | 
| $r   | 用于封装 方法结果 如: Object result = ... ; return ($r)result;   | 
| $w   | 用于将 基础类型转换成，包装类型 如 Integer a1=($w)123;   | 
| $_   | 设置返回结果 $_ s=($w)1; 相当于 return  ($w)1;   | 
| $sig   | 获取方法中 所有参数类型，数组形式展现   | 
| $type   | 获取方法结果的Class   | 
| $class   | 获取当前方法 所在类的Class   | 


特殊语法演示：
```
ctMethod.insertBefore(" System.out.println(this==$0);");
ctMethod.insertBefore(" System.out.println($1);");
ctMethod.insertBefore(" System.out.println($2);");
ctMethod.insertBefore(" System.out.println(java.util.Arrays.toString($args));");
ctMethod.insertBefore(" System.out.println(append($$));");
ctMethod.insertBefore(" System.out.println(java.util.Arrays.toString($sig));");
ctMethod.insertBefore(" System.out.println($type);");
ctMethod.insertBefore(" System.out.println($class);");
ctMethod.insertBefore(" System.out.println($class);");
ctMethod.insertAfter("  Integer a1= ($w)3;");
ctMethod.insertAfter(" $_= ($r)getInt();");
ctMethod.insertAfter("return ($w)3;");
```

## 三、实现 Server 埋点处理

---
概要：
1. 确定采集目标
2. 实现数据采集并打印至日志

// 需求：可直接用于你们的项目，来打印server 方法的执行时间 和参数
// server 配置 com.tuling.server.impl.*
//1 实现一个简单的通配符 规则

1. 确定采集目标

采集目标即找出哪些是需要监控的方法 。这里采取的办法是通过参数配置来实现采集的目标。通过通配符正则匹配的方式配置需要采集类。方法采集范围是 当前类所有的public方法.
### 2.实现数据采集并打印至日志
流程如下：
1. 编写参数解析方法
2. 编写监控起始方法
3. 编写监控结束方法
4. 基于javassist 实现插桩






