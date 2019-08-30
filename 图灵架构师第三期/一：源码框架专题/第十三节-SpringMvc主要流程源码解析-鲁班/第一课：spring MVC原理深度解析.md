**主讲：**图灵鲁班
**时间：**2019/7/7


**课程概要**
1. spring mvc 设计思想与体系结构组成
2. mvc 执行流程解析
## 一、spring mvc 功能特性

---
### 1、回顾servlet 与jsp 执行过程
![图片](https://images-cdn.shimo.im/4yigtQOE8nMbrSlM/image.png!thumbnail)

**流程说明：**
1. 请求Servlet
2. 处理业务逻辑
3. 设置业务Model
4. forward jsp Servlet
5.  jsp Servlet 解析封装html 返回
### **2、spring mvc 功能特性：**
spring mvc本质上还是在使用Servlet处理，并在其基础上进行了封装简化了开发流程，提高易用性、并使用程序逻辑结构变得更清晰
  1. 基于注解的URL映谢
  2. 表单参数映射
  3. 缓存处理
  4. 全局统一异常处理
  5. 拦截器的实现
  6. 下载处理
### 3、请求处理流程
![图片](https://images-cdn.shimo.im/ZtHZCJJg5Lg7QU49/image.png!thumbnail)
### 4、spring mvc 示例：
为便于理解，这里给出一个最简单，配置最少的spring mvc 示例：
web.xml servlet配置：
```
<servlet>
    <servlet-name>dispatcherServlet</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    <init-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>
            classpath:/spring-mvc.xml
        </param-value>
    </init-param>
</servlet>
<servlet-mapping>
    <servlet-name>dispatcherServlet</servlet-name>
    <url-pattern>/</url-pattern>
</servlet-mapping>
```

编写Control 方法：
```
public class SimpleControl implements Controller {
    @Override
    public ModelAndView handleRequest(HttpServletRequest request, HttpServletResponse response) throws Exception {
        ModelAndView mv = new ModelAndView("/WEB-INF/page/userView.jsp");
        mv.addObject("name", "luban is good man");
        return mv;
    }
}
```
配置spring-mvc.xml
```
<bean name="/hello.do" class="com.tuling.control.SimpleControl"/>
```

- [ ] 执行测试演示：


**整个过程是如何实现的？**
1. dispatchServlet 如何找到对应的Control？
2. 如何执行调用Control 当中的业务方法？

在面试中要回答好上述问题，就必须得弄清楚spring mvc 的体系组成。
## 二、mvc 体系结构详解

---
### spring mvc 框架解决的问题
从技术角度去思考 任何一个现存的框架都有其存在理由，而这个理由就是解决实际的问题。或者提供更好的解决问题的方案。spring mvc 它解决了什么问题呢？

1. URL映射
2. 表单参数映射
3. 调用目标Control
4. 数据模型映射
5. 视图解析
6. 异常处理

上术解决在spring mvc 中都体现在如下组件当中
* **HandlerMapping **'hændlə  'mæpɪŋ
  * url与控制器的映谢
* **HandlerAdapter**** **** **'hændlə  ə'dæptə
  * 控制器执行适配器
* **ViewResolver **vjuː  riː'zɒlvə
  *  视图仓库
* **view**
  * 具体解析视图
* **HandlerExceptionResolver  **'hændlə  ɪk'sepʃ(ə)n  riː'zɒlvə
  * 异常捕捕捉器
* **HandlerInterceptor**  'hændlə  ɪntə'septə
  * 拦截器

其对应具体uml如下 图：
![图片](https://images-cdn.shimo.im/KgRjG50ru80SpIQD/image.png!thumbnail)

mvc 各组件执行流程
![图片](https://images-cdn.shimo.im/amwSsViboTYhHk2P/image.png!thumbnail)
### 
### 
### **HandlerMapping 详解**
其为mvc 中url路径与Control对像的映射，DispatcherServlet 就是基于此组件来寻找对应的Control，如果找不到就会报 No mapping found for HTTP request with URI的异常。

HandlerMapping 接口结构分析：
![图片](https://uploader.shimo.im/f/ocYJddIVbtcypuLo.png!thumbnail)

HandlerMapping  作用是通过url找到对应的Handler ，但其HandlerMapping.getHandler()方法并不会直接返回Handler 对像，而是返回 HandlerExecutionChain 对像在通过  HandlerExecutionChain.getHandler() 返回最终的handler

![图片](https://uploader.shimo.im/f/gw9HFxulqrkP8r2R.png!thumbnail)

常用实现类：
![图片](https://images-cdn.shimo.im/03GGNdm0nUAeEIIP/image.png!thumbnail)

目前主流的三种mapping 如下：
1. SimpleUrlHandlerMapping：基于手动配置 url 与control 映谢
2. BeanNameUrlHandlerMapping:  基于ioc name 中已 "/" 开头的Bean时行 注册至映谢.
3. RequestMappingHandlerMapping：基于@RequestMapping注解配置对应映谢

**SimpleUrlHandlerMapping**
演示基于 SimpleUrlHandlerMapping配置映谢。
编写mvc 文件
```
<!--简单控制器-->
<bean name="simpleControl" class="com.tuling.control.SimpleControl"/>
<bean class="org.springframework.web.servlet.handler.SimpleUrlHandlerMapping">
    <property name="urlMap">
        <props>
            <prop key="/hello.do">
                simpleControl
            </prop>
        </props>
    </property>
</bean>
```

SimpleUrlHandlerMapping体系结构：
![图片](https://uploader.shimo.im/f/D9QLkS8ThFQOW6fX.png!thumbnail)


初始化SimpleUrlHandlerMapping流程关键源码：
>>org.springframework.web.servlet.handler.SimpleUrlHandlerMapping#setUrlMap
>>org.springframework.web.servlet.handler.SimpleUrlHandlerMapping#initApplicationContext
>>org.springframework.web.servlet.handler.SimpleUrlHandlerMapping#registerHandlers
> // /表示根路径 /* 表示默认路径
>>org.springframework.web.servlet.handler.AbstractUrlHandlerMapping#registerHandler()

获取 Handler流程关键源码:
>>org.springframework.web.servlet.DispatcherServlet#doService
>>org.springframework.web.servlet.DispatcherServlet#doDispatch
>>org.springframework.web.servlet.DispatcherServlet#getHandler
>>org.springframework.web.servlet.handler.AbstractHandlerMapping#getHandler
>>org.springframework.web.servlet.handler.AbstractUrlHandlerMapping#getHandlerInternal
>  // 获取URL路径
> >org.springframework.web.util.UrlPathHelper#getPathWithinApplication
> // 查找handler
>>org.springframework.web.servlet.handler.AbstractUrlHandlerMapping#lookupHandler
> // 封装执行链
>>org.springframework.web.servlet.handler.AbstractHandlerMapping#getHandlerExecutionChain

** ****BeanNameUrlHandlerMapping**
BeanNameUrlHandlerMapping 实现上与 SimpleUrlHandlerMapping 一至，唯一区别在于 继承自AbstractDetectingUrlHandlerMapping ，通过对应detectHandlers 可以在无配置的情况下发现url 与handler 映射。
结构图：
![图片](https://uploader.shimo.im/f/vNpLve63ZkE93Iwv.png!thumbnail)


**RequestMappingHandlerMapping**
 其基于注解实现，在后续章节讲解注解映谢的时候在详细讲。

Handler 类型
在 AbstractUrlHandlerMapping 我们可以看到存储handler 的Map 值类型是Object ，是否意味着所有的类都可以做来Handler 来使用？
![图片](https://uploader.shimo.im/f/uiNJbg9htH4nlu8M.png!thumbnail)

Handler  对应类型如下如图：
![图片](https://uploader.shimo.im/f/fuDY0d45cxgqykeF.png!thumbnail)
* Controller 接口：
* HttpRequestHandler 接口：
* HttpServlet 接口：
* @RequestMapping方法注解

可以看出 Handler 没有统一的接口，当dispatchServlet获取当对应的Handler之后如何调用呢？调用其哪个方法？这里有两种解决办法，**一是用instanceof 判断Handler 类型然后调用相关方法 。二是通过引入适配器实现，每个适配器实现对指定Handler的调用。**spring 采用后者。

### **HandlerAdapter详解**
这里spring mvc 采用适配器模式来适配调用指定Handler，根据Handler的不同种类采用不同的Adapter,其Handler与 HandlerAdapter 对应关系如下:
| Handler类别   | 对应适配器   | 描述   | 
|:----|:----|:----|
| Controller   | SimpleControllerHandlerAdapter   | 标准控制器，返回ModelAndView   | 
| HttpRequestHandler   | HttpRequestHandlerAdapter   | 业务自行处理 请求，不需要通过modelAndView 转到视图   | 
| Servlet   | SimpleServletHandlerAdapter   | 基于标准的servlet 处理   | 
| HandlerMethod   | RequestMappingHandlerAdapter   | 基于@requestMapping对应方法处理   | 

HandlerAdapter  接口方法
![图片](https://images-cdn.shimo.im/IZdWTPapXBYQzaRx/image.png!thumbnail)

HandlerAdapter  接口结构图
![图片](https://images-cdn.shimo.im/tNKGltBfhoEqCEsi/image.png!thumbnail)

- [ ] 演示基于Servlet 处理  SimpleServletHandlerAdapter
```
<!-- 配置控制器 -->
<bean id="/hello.do" class="com.tuling.mvc.control.HelloServlet"/>

<!-- 配置适配器 -->
<bean class="org.springframework.web.servlet.handler.SimpleServletHandlerAdapter"/>
```

```
// 标准Servlet
public class HelloServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.getWriter().println("hello luban ");
    }
}
```
上述例子中当IOC 中实例化这些类之后 DispatcherServlet 就会通过
org.springframework.web.servlet.DispatcherServlet#getHandlerAdapter() 方法查找对应handler的适配器 ，如果找不到就会报 如下异常 。
>javax.servlet.ServletException: No adapter for handler [com.tuling.control.SimpleControl@3c06b5d5]: The DispatcherServlet configuration needs to include a HandlerAdapter that supports this handler
>org.springframework.web.servlet.DispatcherServlet.getHandlerAdapter(DispatcherServlet.java:1198)
>org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:943)


### **ViewResolver 与View 详解**
找到应的Adapter 之后就会基于适配器调用业务处理，处理完之后业务方会返回一个ModelAndView ，在去查找对应的视图进行处理。其在**org.springframework.web.servlet.DispatcherServlet#resolveViewName()**** **中遍历 viewResolvers 列表查找，如果找不到就会报一个 Could not resolve view with name 异常。

![图片](https://images-cdn.shimo.im/2GnBrLuWvSwdR40e/image.png!thumbnail)


BeanNameViewREsolver示例：
 添加自定义视图:
```
public class MyView implements View {
    @Override
    public void render(Map<String, ?> model, HttpServletRequest 
            request, HttpServletResponse response) throws Exception {
        response.getWriter().print("hello luban good man.");
    }
}
```

配置视图解析器：
<**bean ****name=****"myView" ****class=****"com.tuling.control.MyView"**/>
<**bean ****class=****"org.springframework.web.servlet.view.BeanNameViewResolver"**/>

修改视图跳转方法 ：
**public **ModelAndView handleRequest(HttpServletRequest request, HttpServletResponse response) **throws **Exception {
    ModelAndView mv = **new **ModelAndView(**"myView"**);
    mv.addObject(**"name"**, **"luban is good man"**);
    **return **mv;
}

InternalResourceViewResolver 示例：
*<!--资源解析器 -->*
<**bean ****class=****"org.springframework.web.servlet.view.InternalResourceViewResolver"**>
    <**property ****name=****"prefix" ****value=****"/WEB-INF/page/"**/>
    <**property ****name=****"suffix" ****value=****".jsp"**/>
    <**property ****name=****"viewClass" ****value=****"org.springframework.web.servlet.view.InternalResourceView"**/>
</**bean**>




在下一步就是基于ViewResolver**.**resolveViewName() 获取对应View来解析生成Html并返回 。对应VIEW结构如下：
![图片](https://images-cdn.shimo.im/OF1ug8QGCTET8R61/image.png!thumbnail)

### 
### 
### 
