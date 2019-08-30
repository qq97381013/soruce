1. spring 集成myBatis
2. 动态化SQL与脚本解析器


## 一、spring 集成myBatis

---
### 核心使用：
基础集成使用：
1、配置 SqlSessionFactoryBean
```
<bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
    <property name="dataSource" ref="dataSource"/>
</bean>
```

2、配置 MapperFactoryBean
```
<bean id="userMapper" class="org.mybatis.spring.mapper.MapperFactoryBean">
    <property name="mapperInterface" value="com.tuling.mybatis.dao.UserMapper"/>
    <property name="sqlSessionFactory" ref="sqlSessionFactory"/>
</bean>
```

 3、获取mapper 对像执行业务方法
```
context = new ClassPathXmlApplicationContext("spring.xml");
UserMapper mapper = context.getBean(UserMapper.class);
System.out.println(mapper.selectByid(1));
```

对像说明：
FactoryBean：
工厂Bean 用于 自定义生成Bean对像，当在ioc 中配置FactoryBean 的实例时，最终通过bean id 对应的是FactoryBean.getObject()实例，而非FactoryBean 实例本身
SqlSessionFactoryBean：
生成SqlSessionFactory 实例，该为单例对像，作用于整个应用生命周期。常用属性如下：
* dataSource：   数据源(必填)
* configLocation：指定mybatis-config.xml 的内容，但其设置的<dataSource> <properties> <environments> 将会失效(选填)
* mapperLocations：指定mapper.xml 的路径，相当于mybatis-config.xml 中<mappers> 元素配置，(选填)

MapperFactoryBean：
生成对应的Mapper对像，通常为单例，作用于整个应用生命周期。常用属性如下：
* mapperInterface：mapper 接口      (必填)
* sqlSessionFactory：会话工厂实例 引用 (必填)

关于Mapper 单例情况下是否存在线程安全的问题?
 在原生的myBatis 使用中mapper 对像的生命期是与SqlSession同步的，不会存在线程安全问题，现在单例的mapper 是如何解决线程安全的问题的呢？

### 核心流程解析：
SQL session 集成结构：
![图片](https://uploader.shimo.im/f/TYyDHcdqo8sTKq9S.png!thumbnail)

初始化流程
// 创建 会话模板 SqlSessionTemplate
>>org.mybatis.spring.mapper.MapperFactoryBean#MapperFactoryBean()
>> org.mybatis.spring.support.SqlSessionDaoSupport#setSqlSessionFactory
>> org.mybatis.spring.SqlSessionTemplate#SqlSessionTemplate()
>>org.mybatis.spring.SqlSessionTemplate.SqlSessionInterceptor 

// 创建接口
>> org.mybatis.spring.mapper.MapperFactoryBean#getObject
>> org.mybatis.spring.SqlSessionTemplate#getMapper
>>org.apache.ibatis.session.Configuration#getMapper

// 执行查询
>>com.tuling.mybatis.dao.UserMapper#selectByid
> >org.apache.ibatis.binding.MapperProxy#invoke
> >org.mybatis.spring.SqlSessionTemplate#selectOne(java.lang.String)
> >org.mybatis.spring.SqlSessionTemplate#sqlSessionProxy#selectOne(java.lang.String)
> >org.mybatis.spring.SqlSessionTemplate.SqlSessionInterceptor#invoke
> >org.mybatis.spring.SqlSessionUtils#getSqlSession()
> >org.apache.ibatis.session.SqlSessionFactory#openSession()
>org.apache.ibatis.session.defaults.DefaultSqlSession#selectOne()

每次查询都会创建一个新的 SqlSession 会话，一级缓存还会生效吗？
 通过前几次课我们了解到 一级缓存的条件是必须相同的会话，所以缓存通过和spring 集成之后就不会生效了。除非使用spring 事物 这时就不会在重新创建会话。
### 事物使用 :
spring 事物没有针对myBatis的配置，都是一些常规事物配置：
```
<!--添加事物配置-->
<bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
    <constructor-arg ref="dataSource"/>
</bean>
<!--事物注解配置-->
<tx:annotation-driven/>
```

添加事物注解：
```
@Transactional()
public User getUser2(Integer id) {
    userMapper.selectByid(id);
    return userMapper.selectByid(id);
}
```

执行测试发现 当调用getUser2 方法时两次查询不在重复创建 sqlSession。而是共用一个直到getUser2 方法结束。

事物与SqlSession 集成原理： 
其原理前面讲查询流程时有所涉及。每次执行SQL操作前都会通过 getSqlSession 来获取会话。其主要逻辑是 如果当前线程存在事物，并且存在相关会话，就从ThreadLocal中取出 。如果没就从创建一个 SqlSession 并存储到ThreadLocal 当中，共下次查询使用。
相关源码：
>org.mybatis.spring.SqlSessionUtils#getSqlSession()
>org.springframework.transaction.support.TransactionSynchronizationManager#getResource
>org.mybatis.spring.SqlSessionUtils#sessionHolder
>org.apache.ibatis.session.SqlSessionFactory#openSession()
>org.mybatis.spring.SqlSessionUtils#registerSessionHolder
>org.springframework.transaction.support.TransactionSynchronizationManager#isSynchronizationActive
>org.springframework.transaction.support.TransactionSynchronizationManager#bindResource
### 简化Mapper 配置
如果每个mapper 接口都配置*MapperFactoryBean *相当麻烦 可以通过 如下配置进行自动扫描
```
 <mybatis:scan base-package="com.tuling.mybatis.dao"/>
```

其与 spring bean 注解扫描机制类似，所以得加上注解扫描开关的配置
```
<context:annotation-config/>
```
## 二、动态化SQL

---
### 动态命令使用：
* if
* choose (when, otherwise)
* trim (where, set)
* foreach

<trim>示例说明：
```
<trim prefix="where" prefixOverrides="and|or">
    <if test="id != null">
        and id = #{id}
    </if>
    <if test="name != null">
        and name = #{name}
    </if>
</trim>
```
trim属性说明：
* prefix="where"   // 前缀
* prefixOverrides="and|or"  // 前缀要替换的词
* suffix=""   // 添加后缀
*  suffixOverrides="" // 后缀要替换的词

<where>元素说明：
  在where 包裹的SQL前会自动添加 where 字符 并去掉首尾多佘的 and|or 字符 相当于下配置:
> <trim prefix="where" prefixOverrides="and|or" suffixOverrides="and|or"> 

<set>元素说明：
  在set包裹的SQL前会自动添加 set 字符并去掉首尾多佘的 , 字符。

<sql> 元素说明:
  在同一个mapper  多个statement 存在多个相同的sql  片段时，可以通过<sql>元素声明，在通过   <include>  元素进行引用 
声明sql 段
```
<sql id="files">
    id ,name ,createTime
</sql>
```

引用
```
<include refid="files" />
```

<bind> 变量使用
有时需要进行一些额外 逻辑运行，通过 声明<bind>元素，并在其value 属性中添加运算脚本，如下示例 自动给likeName 加上了% 分号，然后就可以用#{likeName} 来使用带%分号的like 运算。
```
<bind name="likeName" value="'%'+ _parameter.getName() +'%'"></bind>
```
内置变量
_databaseid  数据库标识ID
_parameter 当前参数变理

### 自定义模板解释器：
以上的if trim where 等逻辑符都是 myBatis 自带的XMLLanguageDriver 所提供的解释语言，除此之外 我们还可以使用 MyBatis-Velocity 或 mybatis-freemarker 等外部 解释器来编写动态脚本。

mybatis-freemarker 使用
引入mybatis 包：
```
<dependency>
    <groupId>org.mybatis.scripting</groupId>
    <artifactId>mybatis-freemarker</artifactId>
    <version>1.1.2</version>
</dependency>
```

添加sql 语句
```
<select id="selectByIds"
        resultType="com.tuling.mybatis.dao.User"
        lang="org.mybatis.scripting.freemarker.FreeMarkerLanguageDriver">
    select  * from user
    where  id in(${ids?join(',')})
</select>
```

添加接口方法
```
List<User> selectByIds(@Param("ids") List<Integer> ids);
```

