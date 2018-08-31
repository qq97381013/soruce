     主讲：图灵鲁班
      时间：2018/8/29

**概要：**
1. **数据库的事物的基本特性**
2. **Sring 对事物的支持与使用**
3. **aop 事物底层实现原理**

## **一、数据库的事物的基本特性**

---
事物是区分文件存储系统与Nosql数据库重要特性之一，其存在的意义是为了保证即使在并发情况下也能正确的执行crud操作。怎样才算是正确的呢？这时提出了事物需要保证的四个特性即ACID：
* A: 原子性(atomicity)
  * 事物中各项操作，要么全做要么全不做，任何一项操作的失败都会导致整个事物的失败；
* C: 一致性(consistency)
  * 事物结束后系统状态是一致的；
* I:  隔离性(isolation)
  * 并发执行的事物彼此无法看到对方的中间状态；
* D: 持久性(durability)
  * 事物完成后所做的改动都会被持久化，即使发生灾难性的失败。

在高并发的情况下，要完全保证其ACID特性是非常困难的，除非把所有的事物串行化执行，但带来的负面的影响将是性能大打折扣。很多时候我们有些业务对事物的要求是不一样的，所以数据库中设计了四种隔离级别，供用户基于业务进行选择。
| **隔离级别**   | **脏读（Dirty Read）**   | **不可重复读（NonRepeatable Read）**   | **幻读（Phantom Read）**   | 
|:----|:----|:----|:----|
| 未提交读（Read uncommitted）   | 可能   | 可能   | 可能   | 
| 已提交读（Read committed）   | 不可能   | 可能   | 可能   | 
| 可重复读（Repeatable read）   | 不可能   | 不可能   | 可能   | 
| 可串行化（SERIALIZABLE）   | 不可能   | 不可能   | 不可能   | 


**脏读 :**
一个事物读取到另一事物未提交的更新数据
**不可重复读 : **
在同一事物中,多次读取同一数据返回的结果有所不同, 换句话说, 后续读取可以读到另一事物已提交的更新数据. 相反, “可重复读”在同一事物中多次读取数据时, 能够保证所读数据一样, 也就是后续读取不能读到另一事物已提交的更新数据。
**幻读 :**
 查询表中一条数据如果不存在就插入一条，并发的时候却发现，里面居然有两条相同的数据。这就幻读的问题。

- [ ] 代码演示脏读、不可重复读、幻读的情况。

演示源码：[http://git.jiagouedu.com/java-vip/tuling-spring/src/master/tuling-spring-transaction](http://git.jiagouedu.com/java-vip/tuling-spring/src/master/tuling-spring-transaction)

**数据库默认隔离级别：**
Oracle中默认级别是 Read committed
mysql 中默认级别 Repeatable read。另外要注意的是mysql 执行一条查询语句默认是一个独立的事物，所以看上去效果跟Read committed一样。
```
# 查看mysql 的默认隔离级别
SELECT @@tx_isolation
```
## **二、Sring 对事物的支持与使用**

---
### 知识点：
1. spring 事物相关API说明
2. 声明式事物的使用
3. 事物传播机制
### 1、spring 事物相关API说明
spring 事物是在数据库事物的基础上进行封装扩展 其主要特性如下：
  1. 支持原有的数据事物的隔离级别
  2. 加入了事物传播的概念 提供多个事物的和并或隔离的功能
  3. 提供声明式事物，让业务代码与事物分离，事物变得更易用。

怎么样去使用Spring事物呢？spring 提供了三个接口供使用事物。分别是：

* TransactionDefinition
  * 事物定义
* PlatformTransactionManager
  * 事物管理
* TransactionStatus
  * 事物运行时状态

**接口结构图：**
![图片](https://images-cdn.shimo.im/aDuOaOczV9oYXkvX/image.png!thumbnail)

**API说明：**

- [ ] 基于API实现事物
```
public class SpringTransactionExample {
    private static String url = "jdbc:mysql://192.168.0.147:3306/luban2";
    private static String user = "root";
    private static String password = "123456";

    public static Connection openConnection() throws ClassNotFoundException, SQLException {
        Class.forName("com.mysql.jdbc.Driver");
        Connection conn = DriverManager.getConnection("jdbc:mysql://192.168.0.147:3306/luban2", "root", "123456");
        return conn;
    }

    public static void main(String[] args) {
        final DataSource ds = new DriverManagerDataSource(url, user, password);
        final TransactionTemplate template = new TransactionTemplate();
        template.setTransactionManager(new DataSourceTransactionManager(ds));
        template.execute(new TransactionCallback<Object>() {
            @Override
            public Object doInTransaction(TransactionStatus status) {
                Connection conn = DataSourceUtils.getConnection(ds);
                Object savePoint = null;
                try {
                    {
                        // 插入
                        PreparedStatement prepare = conn.
                                prepareStatement("insert INTO account (accountName,user,money) VALUES (?,?,?)");
                        prepare.setString(1, "111");
                        prepare.setString(2, "aaaa");
                        prepare.setInt(3, 10000);
                        prepare.executeUpdate();
                    }
                    // 设置保存点
                    savePoint = status.createSavepoint();
                    {
                        // 插入
                        PreparedStatement prepare = conn.
                                prepareStatement("insert INTO account (accountName,user,money) VALUES (?,?,?)");
                        prepare.setString(1, "222");
                        prepare.setString(2, "bbb");
                        prepare.setInt(3, 10000);
                        prepare.executeUpdate();
                    }
                    {
                        // 更新
                        PreparedStatement prepare = conn.
                                prepareStatement("UPDATE account SET money= money+1 where user=?");
                        prepare.setString(1, "asdflkjaf");
                        Assert.isTrue(prepare.executeUpdate() > 0, "");
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                } catch (Exception e) {
                    System.out.println("更新失败");
                    if (savePoint != null) {
                        status.rollbackToSavepoint(savePoint);
                    } else {
                        status.setRollbackOnly();
                    }
                }
                return null;
            }
        });
    }
}
```
### 2、声明示事物
我们前面是通过调用API来实现对事物的控制，这非常的繁琐，与直接操作JDBC事物并没有太多的改善，所以Spring提出了声明示事物，使我们对事物的操作变得非常简单，甚至不需要关心它。
- [ ] 演示声明示事物使用
[spring-tx.xml](https://attachments-cdn.shimo.im/lkDa471z7ocarIzx/spring_tx.xml)

配置spring.xml
```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xmlns:tx="http://www.springframework.org/schema/tx"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="
        http://www.springframework.org/schema/beans
        http://www.springframework.org/schema/beans/spring-beans.xsd
        http://www.springframework.org/schema/tx
        http://www.springframework.org/schema/tx/spring-tx.xsd
        http://www.springframework.org/schema/context
        http://www.springframework.org/schema/context/spring-context.xsd
        http://www.springframework.org/schema/aop
        http://www.springframework.org/schema/aop/spring-aop.xsd">

    <context:annotation-config/>
    <context:component-scan base-package="com.tuling.service.**">
    </context:component-scan>

    <bean class="org.springframework.jdbc.core.JdbcTemplate">
        <property name="dataSource" ref="dataSource"/>
    </bean>

    <!-- similarly, don't forget the PlatformTransactionManager -->
    <bean id="txManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
        <property name="dataSource" ref="dataSource"/>
    </bean>
    <!-- don't forget the DataSource -->
    <bean id="dataSource" class="org.springframework.jdbc.datasource.DriverManagerDataSource">
        <constructor-arg name="url" value="jdbc:mysql://192.168.0.147/luban2"/>
        <constructor-arg name="username" value="root"/>
        <constructor-arg name="password" value="123456"/>
    </bean>
    <tx:annotation-driven transaction-manager="txManager"></tx:annotation-driven>
</beans>
```
编写服务类
```
@Transactional
public void addAccount(String name, int initMenoy) {
    String accountid = new SimpleDateFormat("yyyyMMddhhmmss").format(new Date());
    jdbcTemplate.update("insert INTO account (accountName,user,money) VALUES (?,?,?)", accountid, name, initMenoy);
    // 人为报错
    int i = 1 / 0;
}
```

- [ ] 演示添加 @Transactional 注解和不添加注解的情况。
### 3、事物传播机制
| **类别**   | **事物传播类型**   | **说明**   | 
|:----:|:----|
| 支持当前事物   | PROPAGATION_REQUIRED  （必须的）   | 如果当前没有事物，就新建一个事物，如果已经存在一个事物中，加入到这个事物中。这是最常见的选择。 | 
|    | PROPAGATION_SUPPORTS  （支持）   | 支持当前事物，如果当前没有事物，就以非事物方式执行。 | 
|    | PROPAGATION_MANDATORY  （强制）   | 使用当前的事物，如果当前没有事物，就抛出异常。 | 
| 不支持当前事物   | PROPAGATION_REQUIRES_NEW  (隔离)   | 新建事物，如果当前存在事物，把当前事物挂起。 | 
|    | PROPAGATION_NOT_SUPPORTED  (不支持)   | 以非事物方式执行操作，如果当前存在事物，就把当前事物挂起。 | 
|    | PROPAGATION_NEVER(强制非事物)   | 以非事物方式执行，如果当前存在事物，则抛出异常。 | 
| 套事物   | PROPAGATION_NESTED  （嵌套事物）   | 如果当前存在事物，则在嵌套事物内执行。如果当前没有事物，则执行与PROPAGATION_REQUIRED类似的操作。   | 

**常用事物传播机制：**
* PROPAGATION_REQUIRED，
  * 这个也是默认的传播机制；
* PROPAGATION_NOT_SUPPORTED
  * 可以用于发送提示消息，站内信、短信、邮件提示等。不属于并且不应当影响主体业务逻辑，即使发送失败也不应该对主体业务逻辑回滚。
* PROPAGATION_REQUIRES_NEW
  * 总是新启一个事物，这个传播机制适用于不受父方法事物影响的操作，比如某些业务场景下需要记录业务日志，用于异步反查，那么不管主体业务逻辑是否完成，日志都需要记录下来，不能因为主体业务逻辑报错而丢失日志；

- [ ] 演示常用事物的传播机制

**用例1:**
创建用户时初始化一个帐户，表结构和服务类如下。
| **表结构**   | **服务类**   | **功能描述**   | 
|:----|:----|:----|
| user   | UserSerivce   | 创建用户，并添加帐户   | 
| account   | AccountService   | 添加帐户   | 

UserSerivce.createUser(name) 实现代码
```
@Transactional
public void createUser(String name) {
    // 新增用户基本信息
    jdbcTemplate.update("INSERT INTO `user` (name) VALUES(?)", name);
    //调用accountService添加帐户
    accountService.addAccount(name, 10000);
 ｝
```

AccountService.addAccount(name,initMoney) 实现代码（方法的最后有一个异常）
```
@Transactional(propagation = Propagation.REQUIRED)
public void addAccount(String name, int initMoney) {
    String accountid = new SimpleDateFormat("yyyyMMddhhmmss").format(new Date());
    jdbcTemplate.update("insert INTO account (accountName,user,money) VALUES (?,?,?)", accountid, name, initMenoy);
    // 出现分母为零的异常
    int i = 1 / 0;
}
```

实验预测一：
|    | createUser   | addAccount(异常)   | 预测结果   | 
|:----|:----|:----|:----|
| 场景一   | 无事物   | required   | user （成功） Account（不成功） 正确   | 
| 场景二   | required   | 无事物   | user （不成功） Account（不成功） 正确   | 
| 场景三   | required   | not_supported   | user （不成功） Account（成功）正确   | 
| 场景四   | required   | required_new   | user （不成功） Account（不成功）正确   | 
| 场景五   | required  (异常移至createUser方法未尾) | required_new   | user （不成功） Account（成功）正确   | 
| 场景六   | required  (异常移至createUser方法未尾)  （addAccount 方法称至当前类）     | required_new   | user （不成功） Account（不成功）   | 

## **三、aop 事物底层实现原理**

---
讲事物原理之前我们先来做一个实验，当场景五的环境改变，把addAccount 方法移至UserService 类下，其它配置和代码不变：
```
@Override
@Transactional
public void createUser(String name) {
    jdbcTemplate.update("INSERT INTO `user` (name) VALUES(?)", name);
    addAccount(name, 10000);
    // 人为报错
    int i = 1 / 0;
}

@Transactional(propagation = Propagation.REQUIRES_NEW)
public void addAccount(String name, int initMoney) {
    String accountid = new SimpleDateFormat("yyyyMMddhhmmss").format(new Date());
    jdbcTemplate.update("insert INTO account (accountName,user,money) VALUES (?,?,?)", accountid, name, initMoney);
}
```

- [ ] 演示新场景

经过演示我们发现得出的结果与场景五并不 一至，required_new 没有起到其对应的作用。原因在于spring 声明示事物使用动态代理实现，而当调用同一个类的方法时，是会不会走代理逻辑的，自然事物的配置也会失效。

通过一个动态代理的实现来模拟这种场景
```
UserSerivce proxyUserSerivce = (UserSerivce) Proxy.newProxyInstance(LubanTransaction.class.getClassLoader(),
        new Class[]{UserSerivce.class}, new InvocationHandler() {
            @Override
            public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                try {
                    System.out.println("开启事物:"+method.getName());
                    return method.invoke(userSerivce, args);
                } finally {
                    System.out.println("关闭事物:"+method.getName());
                }
            }
        });
proxyUserSerivce.createUser("luban");
```

当我们调用createUser 方法时 仅打印了 createUser  的事物开启、关闭，并没有打印addAccount 方法的事物开启、关闭，由此可见addAccount  的事物配置是失效的。

如果业务当中上真有这种场景该如何实现呢？在spring xml中配置 暴露proxy 对象，然后在代码中用AopContext.currentProxy() 就可以获当前代理对象

```
<!-- 配置暴露proxy -->
<aop:aspectj-autoproxy expose-proxy="true"/>
```

```
// 基于代理对象调用创建帐户，事物的配置又生效了
((UserSerivce) AopContext.currentProxy()).addAccount(name, 10000);
```

